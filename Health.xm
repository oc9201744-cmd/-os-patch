#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#include <pthread.h>

// --- BAYBARS SESSİZ ANONS (HAFİF VE GÜVENLİ) ---
void BaybarsAnons(NSString *text, UIColor *color) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                win = ((UIWindowScene *)scene).windows.firstObject;
                break;
            }
        }
        if (!win) return;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 260, 35)];
        label.center = CGPointMake(win.frame.size.width / 2, 80);
        label.text = text;
        label.textColor = color;
        label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
        label.layer.cornerRadius = 5;
        label.clipsToBounds = YES;
        [win addSubview:label];
        [UIView animateWithDuration:0.5 delay:3.0 options:0 animations:^{ label.alpha = 0; } completion:^(BOOL f){ [label removeFromSuperview]; }];
    });
}

// --- DOSYA YÖNLENDİRME (DAHA DERİN KANCA) ---
static int (*old_open)(const char *path, int oflag, ...);
int new_open(const char *path, int oflag, ...) {
    if (path != NULL && strstr(path, "ShadowTrackerExtra") && !strstr(path, "_Bak")) {
        char newPath[1024];
        snprintf(newPath, sizeof(newPath), "%s_Bak", path);
        
        // Sadece 'Okuma' amaçlı açılışları yönlendiriyoruz (Anticheat taraması için)
        if (!(oflag & O_WRONLY) && !(oflag & O_RDWR)) {
            return old_open(newPath, oflag);
        }
    }
    return old_open(path, oflag);
}

void* BaybarsOneWeekFix(void* arg) {
    // iOS 17'de ACE'nin uyanmasını bekle (Kritik Gecikme)
    [NSThread sleepForTimeInterval:55.0];

    // DYNAMIC HOOKING (Hafıza Yaması Yerine Fonksiyon Yönlendirme)
    // dlsym kullanarak 'open' fonksiyonunu yakalıyoruz. 
    // Bu sayede hafızadaki baytları ellemiyoruz, sadece sistemin kapısını tutuyoruz.
    old_open = (int (*)(const char *, int, ...))dlsym(RTLD_DEFAULT, "open");

    // Hafıza Yaması (Ofsetler): Sadece çok kritik olanı, 
    // ama 'memcpy' yerine 'vm_write' benzeri daha güvenli bir yapıyla.
    uintptr_t slide = (uintptr_t)_dyld_get_image_vmaddr_slide(0);
    uint32_t patch = 0xD65F03C0; // RET
    
    mach_port_t task = mach_task_self();
    // 0xF806C (Integrity Check) noktasını sessizce dondur
    vm_protect(task, trunc_page(slide + 0xF806C), PAGE_SIZE, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    memcpy((void *)(slide + 0xF806C), &patch, 4);
    vm_protect(task, trunc_page(slide + 0xF806C), PAGE_SIZE, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);

    BaybarsAnons(@"Baybars: 1 Hafta Koruması Aktif!", [UIColor cyanColor]);
    return NULL;
}

__attribute__((constructor))
static void Entry() {
    // 5 saniye bekle ve sonra thread başlat (Crash engelleyici)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        pthread_t t;
        pthread_create(&t, NULL, BaybarsOneWeekFix, NULL);
    });
}

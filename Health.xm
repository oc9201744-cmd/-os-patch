#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <fcntl.h>
#import <sys/stat.h>
#include <pthread.h> // Hata veren kısım düzeltildi

// --- BAYBARS GÖRSEL ANONS ---
void BaybarsAnons(NSString *text, UIColor *color) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        // Yeni iOS sürümleri için keyWindow hatası giderildi
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* windowScene in [UIApplication sharedApplication].connectedScenes) {
                if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                    window = windowScene.windows.firstObject;
                    break;
                }
            }
        } else {
            window = [UIApplication sharedApplication].keyWindow;
        }

        if (!window) return;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
        label.center = CGPointMake(window.frame.size.width / 2, 110);
        label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.85];
        label.textColor = color;
        label.textAlignment = NSTextAlignmentCenter;
        label.text = text;
        label.font = [UIFont boldSystemFontOfSize:15];
        label.layer.cornerRadius = 12;
        label.clipsToBounds = YES;
        label.layer.borderColor = color.CGColor;
        label.layer.borderWidth = 1.0;
        [window addSubview:label];
        [UIView animateWithDuration:0.5 delay:4.0 options:0 animations:^{ label.alpha = 0; } completion:^(BOOL f){ [label removeFromSuperview]; }];
    });
}

// --- DOSYA YÖNLENDİRME (HOOK) ---
static int (*old_open)(const char *path, int oflag, ...);
static int (*old_stat)(const char *path, struct stat *buf);
static int (*old_access)(const char *path, int mode);

int new_open(const char *path, int oflag, ...) {
    if (path != NULL && strstr(path, "ShadowTrackerExtra") && !strstr(path, "_Bak")) {
        char newPath[1024];
        snprintf(newPath, sizeof(newPath), "%s_Bak", path);
        va_list args;
        va_start(args, oflag);
        mode_t mode = va_arg(args, int);
        va_end(args);
        return old_open(newPath, oflag, mode);
    }
    return old_open(path, oflag);
}

int new_stat(const char *path, struct stat *buf) {
    if (path != NULL && strstr(path, "ShadowTrackerExtra") && !strstr(path, "_Bak")) {
        char newPath[1024];
        snprintf(newPath, sizeof(newPath), "%s_Bak", path);
        return old_stat(newPath, buf);
    }
    return old_stat(path, buf);
}

void* BaybarsFinalWorker(void* arg) {
    [NSThread sleepForTimeInterval:7.0];
    BaybarsAnons(@"Baybars: Sistem Hazırlanıyor...", [UIColor orangeColor]);

    [NSThread sleepForTimeInterval:45.0];

    // Fonksiyonları sistemden yakala
    old_open = (int (*)(const char *, int, ...))dlsym(RTLD_DEFAULT, "open");
    old_stat = (int (*)(const char *, struct stat *))dlsym(RTLD_DEFAULT, "stat");
    
    // Kingmod tarzı Ofset yamaları (Pubg.txt ve anogs.c analizi)
    uintptr_t slide = (uintptr_t)_dyld_get_image_vmaddr_slide(0);
    
    // Anticheat raporlama ve tarama ofsetlerini sustur
    uint32_t ret_code = 0xD65F03C0; 
    mach_port_t task = mach_task_self();
    
    // 0xF806C ve 0x2DF68 (AnoSDK) noktalarını kör et
    vm_protect(task, trunc_page(slide + 0xF806C), PAGE_SIZE, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    memcpy((void *)(slide + 0xF806C), &ret_code, 4);
    
    vm_protect(task, trunc_page(slide + 0x2DF68), PAGE_SIZE, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    memcpy((void *)(slide + 0x2DF68), &ret_code, 4);

    BaybarsAnons(@"Baybars: Anticheat Yönlendirildi!", [UIColor greenColor]);
    return NULL;
}

__attribute__((constructor))
static void Entry() {
    pthread_t t;
    pthread_create(&t, NULL, BaybarsFinalWorker, NULL);
}

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <fcntl.h>
#import <sys/stat.h>
#include <pthread.h>

// --- BAYBARS GÖRSEL ANONS ---
void BaybarsAnons(NSString *text, UIColor *color) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        // Modern iOS (13.0+) Window bulma mantığı
        for (UIScene* scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                window = ((UIWindowScene *)scene).windows.firstObject;
                break;
            }
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
        label.layer.borderWidth = 1.5;
        [window addSubview:label];
        [UIView animateWithDuration:0.5 delay:4.0 options:0 animations:^{ label.alpha = 0; } completion:^(BOOL f){ [label removeFromSuperview]; }];
    });
}

// --- DOSYA YÖNLENDİRME (HOOK) ---
static int (*old_open)(const char *path, int oflag, ...);
static int (*old_stat)(const char *path, struct stat *buf);

int new_open(const char *path, int oflag, ...) {
    if (path != NULL && strstr(path, "ShadowTrackerExtra") && !strstr(path, "_Bak")) {
        char newPath[1024];
        snprintf(newPath, sizeof(newPath), "%s_Bak", path);
        
        mode_t mode = 0;
        if (oflag & O_CREAT) {
            va_list args;
            va_start(args, oflag);
            mode = va_arg(args, int);
            va_end(args);
            return old_open(newPath, oflag, mode);
        }
        return old_open(newPath, oflag);
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

    // Orijinal fonksiyonları yakala
    old_open = (int (*)(const char *, int, ...))dlsym(RTLD_DEFAULT, "open");
    old_stat = (int (*)(const char *, struct stat *))dlsym(RTLD_DEFAULT, "stat");
    
    uintptr_t slide = (uintptr_t)_dyld_get_image_vmaddr_slide(0);
    uint32_t ret_code = 0xD65F03C0; 
    mach_port_t task = mach_task_self();
    
    // Pubg.txt ve anogs.c'deki kritik noktaları kör et (AnoSDK ve Integrity)
    vm_protect(task, trunc_page(slide + 0xF806C), PAGE_SIZE, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    memcpy((void *)(slide + 0xF806C), &ret_code, 4);
    
    vm_protect(task, trunc_page(slide + 0x2DF68), PAGE_SIZE, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    memcpy((void *)(slide + 0x2DF68), &ret_code, 4);

    BaybarsAnons(@"Baybars: ShadowTracker Yönlendirildi!", [UIColor greenColor]);
    return NULL;
}

__attribute__((constructor))
static void Entry() {
    pthread_t t;
    pthread_create(&t, NULL, BaybarsFinalWorker, NULL);
}

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <sys/sysctl.h>
#import <dlfcn.h>
#import <dobby.h>

/**
 * KINGMOD BYPASS VE HOOK UYARLAMASI (Non-Jailbreak)
 * Alert gösterme hatası (sharedSelector) düzeltildi.
 */

// --- Orijinal Fonksiyon Prototipleri ---
int (*orig_sysctl)(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen);
void* (*orig_dlopen)(const char* path, int mode);

// --- Bypass Fonksiyonları ---

// Anti-Debug (sysctl P_TRACED) Bypass
int my_sysctl(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    int ret = orig_sysctl(name, namelen, oldp, oldlenp, newp, newlen);
    if (namelen >= 4 && name[0] == CTL_KERN && name[1] == KERN_PROC && name[2] == KERN_PROC_PID && name[3] == getpid()) {
        if (oldp && oldlenp && *oldlenp >= sizeof(struct kinfo_proc)) {
            struct kinfo_proc *kp = (struct kinfo_proc *)oldp;
            if (kp->kp_proc.p_flag & P_TRACED) {
                kp->kp_proc.p_flag &= ~P_TRACED;
            }
        }
    }
    return ret;
}

// --- Hile Aktif Bildirimi ---
void show_active_alert() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // En üstteki pencereyi ve kontrolcüyü bul
        UIWindow *window = nil;
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

        UIViewController *rootViewController = window.rootViewController;
        if (rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"KINGMOD"
                                                                           message:@"Bypass ve Hile Aktif Edildi!\nİyi Oyunlar Kanka."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Tamam"
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil];
            [alert addAction:okAction];
            
            // Eğer halihazırda bir controller sunuluyorsa onun üzerinden göster
            UIViewController *topController = rootViewController;
            while (topController.presentedViewController) {
                topController = topController.presentedViewController;
            }
            [topController presentViewController:alert animated:YES completion:nil];
            NSLog(@"[KINGMOD] Alert başarıyla gösterildi.");
        }
    });
}

// --- Ana Giriş (Constructor) ---
__attribute__((constructor)) static void initialize_bypass() {
    NSLog(@"[KINGMOD] Bypass Motoru Başlatılıyor...");

    // 1. Sistem Fonksiyonlarını Hookla
    DobbyHook((void *)sysctl, (void *)my_sysctl, (void **)&orig_sysctl);
    
    // 2. Hile Aktif Yazısını Konsola Yaz
    NSLog(@"*******************************************");
    NSLog(@"*      KINGMOD BYPASS AKTİF EDİLDİ        *");
    NSLog(@"*******************************************");
    
    // 3. Uygulama açıldığında ekranda Alert göster
    dispatch_async(dispatch_get_main_queue(), ^{
        show_active_alert();
    });
}

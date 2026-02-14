#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <mach-o/dyld.h>
#include <substrate.h>

// --- STANDART VERI TIPLERI ---
typedef long long int64_t_ace;
typedef unsigned long long qword_ace;

// 1. Raporlayici (bak 4.txt / bak 5.txt)
static int64_t_ace (*orig_sub_F012C)(void *a1);
static int64_t_ace hook_sub_F012C(void *a1) {
    NSLog(@"[Gemini] Raporlayici (F012C) yakalandi.");
    return 0; 
}

// 2. Syscall Watcher (bak 6.txt)
static unsigned char* (*orig_sub_F838C)(int64_t_ace a1, int64_t_ace (**a2)(), unsigned long long a3, qword_ace *a4);
static unsigned char* hook_sub_F838C(int64_t_ace a1, int64_t_ace (**a2)(), unsigned long long a3, qword_ace *a4) {
    NSLog(@"[Gemini] Syscall Watcher (F838C) engellendi.");
    return 0; 
}

// 3. Ana Kontrol Merkezi & Case 35 (bak.txt)
static int64_t_ace (*orig_sub_11D85C)(int64_t_ace a1, int64_t_ace a2, int64_t_ace a3, int64_t_ace a4, ...);
static int64_t_ace hook_sub_11D85C(int64_t_ace a1, int64_t_ace a2, int64_t_ace a3, int64_t_ace a4, ...) {
    if (a2 != 0 && *(unsigned char *)(a2 + 168) == 0x35) {
        NSLog(@"[Gemini] Hafiza Taramasi (Case 35) atlatildi.");
        return 1; 
    }
    return orig_sub_11D85C(a1, a2, a3, a4);
}

// --- BASLATICI ---
__attribute__((constructor))
static void init() {
    // 45 saniye gecikme: Lobiye giris beklemeli
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(45.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
        
        MSHookFunction((void *)(slide + 0xF012C), (void *)hook_sub_F012C, (void **)&orig_sub_F012C);
        MSHookFunction((void *)(slide + 0xF838C), (void *)hook_sub_F838C, (void **)&orig_sub_F838C);
        MSHookFunction((void *)(slide + 0x11D85C), (void *)hook_sub_11D85C, (void **)&orig_sub_11D85C);
        
        NSLog(@"[Gemini] ACE Analiz Hooklari Aktif.");

        // Bildirim gosterme (Lobi kontrolü)
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"GEMINI V13" 
                                   message:@"Bypass Aktif.\nKeyifli oyunlar kanka!" 
                                   preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
        
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = ((UIWindowScene *)scene).windows.firstObject;
                    break;
                }
            }
        }
        if(!window) window = [UIApplication sharedApplication].keyWindow;
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>      // ← dispatch_after, dispatch_time vb. için KRİTİK
#import <stdint.h>                 // ← uintptr_t, int64_t vb. için
#import <substrate.h>              // ← MSHookFunction için (veya <CydiaSubstrate.h>)

// --- Tip tanımlamaları (bunları değiştirmeden bırak) ---
typedef long long int64_t_ace;
typedef unsigned long long qword_ace;

// 1. Raporlayıcı
static int64_t_ace (*orig_sub_F012C)(void *a1);
static int64_t_ace hook_sub_F012C(void *a1) {
    NSLog(@"[Gemini] Raporlayıcı (sub_F012C) yakalandı → bypass");
    return 0;
}

// 2. Syscall watcher
static unsigned char* (*orig_sub_F838C)(int64_t_ace a1, int64_t_ace (**a2)(), unsigned long long a3, qword_ace *a4);
static unsigned char* hook_sub_F838C(int64_t_ace a1, int64_t_ace (**a2)(), unsigned long long a3, qword_ace *a4) {
    NSLog(@"[Gemini] Syscall Watcher (sub_F838C) engellendi → bypass");
    return NULL;
}

// 3. Ana kontrol (case 0x35)
static int64_t_ace (*orig_sub_11D85C)(int64_t_ace a1, int64_t_ace a2, int64_t_ace a3, int64_t_ace a4, ...);
static int64_t_ace hook_sub_11D85C(int64_t_ace a1, int64_t_ace a2, int64_t_ace a3, int64_t_ace a4, ...) {
    if (a2 != 0 && *(unsigned char *)(a2 + 168) == 0x35) {
        NSLog(@"[Gemini] Hafıza taraması (case 35) atlatıldı → bypass");
        return 1;
    }

    va_list args;
    va_start(args, a4);
    int64_t_ace result = orig_sub_11D85C(a1, a2, a3, a4, args);
    va_end(args);

    return result;
}

// --- Başlatıcı ---
__attribute__((constructor))
static void initializer(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(45.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
        
        if (slide == 0) {
            NSLog(@"[Gemini] Uyarı: ASLR slide değeri 0 geldi. Hook'lar başarısız olabilir.");
        }
        
        void *addr_F012C  = (void *)(slide + 0xF012C);
        void *addr_F838C  = (void *)(slide + 0xF838C);
        void *addr_11D85C = (void *)(slide + 0x11D85C);
        
        MSHookFunction(addr_F012C,  (void *)hook_sub_F012C,  (void **)&orig_sub_F012C);
        MSHookFunction(addr_F838C,  (void *)hook_sub_F838C,  (void **)&orig_sub_F838C);
        MSHookFunction(addr_11D85C, (void *)hook_sub_11D85C, (void **)&orig_sub_11D85C);
        
        NSLog(@"[Gemini] ACE Bypass Hook'ları aktif → slide = 0x%lx", slide);
        NSLog(@"[Gemini] F012C  → %p", addr_F012C);
        NSLog(@"[Gemini] F838C  → %p", addr_F838C);
        NSLog(@"[Gemini] 11D85C → %p", addr_11D85C);
        
        // Alert kısmı (isteğe bağlı – sorun çıkarırsa yorum satırına al)
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"GEMINI V13"
                                    message:@"Bypass aktif edildi.\nKeyifli oyunlar kanka!"
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
        if (!window) window = [UIApplication sharedApplication].keyWindow;
        
        if (window && window.rootViewController) {
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        } else {
            NSLog(@"[Gemini] Alert gösterilemedi → window/rootViewController yok");
        }
    });
}
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <mach-o/dyld.h>
#include <substrate.h>
#include <dispatch/dispatch.h>
#include <stdarg.h>
#include <stdint.h>

// --- Tip tanımlamaları ---
typedef long long int64_t_ace;
typedef unsigned long long qword_ace;

// 1. Raporlayıcı fonksiyonu
static int64_t_ace (*orig_sub_F012C)(void *a1);
static int64_t_ace hook_sub_F012C(void *a1) {
    NSLog(@"[Gemini] Raporlayıcı (sub_F012C) yakalandı → bypass");
    return 0;
}

// 2. Syscall / anti-debug watcher
static unsigned char* (*orig_sub_F838C)(int64_t_ace a1, int64_t_ace (**a2)(), unsigned long long a3, qword_ace *a4);
static unsigned char* hook_sub_F838C(int64_t_ace a1, int64_t_ace (**a2)(), unsigned long long a3, qword_ace *a4) {
    NSLog(@"[Gemini] Syscall Watcher (sub_F838C) engellendi → bypass");
    return NULL;
}

// 3. Ana kontrol / pattern tarama fonksiyonu
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

// --- Tweak başlatıcı ---
__attribute__((constructor))
static void initializer(void) {
    // 45 saniye gecikme → Lobi taramalarını atlatmak için kritik süre
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(45.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // ASLR Slide hesaplama (0. index üzerinden)
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
        
        // Eğer slide 0 gelirse hile çalışmaz, loglara bakarsın
        NSLog(@"[Gemini] Hesaplanan Slide: 0x%lx", (unsigned long)slide);
        
        // Hook adreslerini slide ile birleştir
        void *addr_F012C  = (void *)(slide + 0xF012C);
        void *addr_F838C  = (void *)(slide + 0xF838C);
        void *addr_11D85C = (void *)(slide + 0x11D85C);
        
        // Hook'ları uygula
        MSHookFunction(addr_F012C,  (void *)hook_sub_F012C,  (void **)&orig_sub_F012C);
        MSHookFunction(addr_F838C,  (void *)hook_sub_F838C,  (void **)&orig_sub_F838C);
        MSHookFunction(addr_11D85C, (void *)hook_sub_11D85C, (void **)&orig_sub_11D85C);
        
        NSLog(@"[Gemini] V13 Bypass Aktif!");

        // --- Görsel Bildirim (UI İşlemleri Ana Thread'de yapılmalı) ---
        dispatch_async(dispatch_get_main_queue(), ^{
            UIWindow *window = nil;
            if (@available(iOS 13.0, *)) {
                for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                    if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                        window = ((UIWindowScene *)scene).windows.firstObject;
                        break;
                    }
                }
            }
            if (!window) window = [UIApplication sharedApplication].keyWindow;

            if (window && window.rootViewController) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"GEMINI V13"
                                            message:@"Bypass aktif kanka!\nBol killer."
                                            preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
                [window.rootViewController presentViewController:alert animated:YES completion:nil];
            }
        });
    });
}

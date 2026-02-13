#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>
#include <substrate.h>

/*
    GEMINI V63 - VISUAL SURVIVAL EDITION
    - Ekranda "Hile aktif edildi" uyarısı verir.
    - Flag/Bayrak sonrası hayatta kalma (v9) aktif.
    - 60 saniye gecikmeli aktivasyon.
*/

// Orijinal fonksiyonlar
static void* (*orig_case35)(void*);
static int   (*orig_report)(void*);
static void* (*orig_syscall)(void*, void**, unsigned long, void*);

// Flag Survival (Oldmonk) Mantığı
void* h_survival_check(void* a1) {
    if (!a1) return 0;
    void* v1 = *(void**)((uintptr_t)a1 + 0x108); 
    if (!v1) return (void*)0;
    void* v13 = *(void**)((uintptr_t)a1 + 0x110); 
    if (!v13) return (void*)0;
    void* v9 = *(void**)((uintptr_t)v13 + 0x1D0); 
    return v9; 
}

// Rapor Susturucu
int h_sub_F012C(void* a1) { return 0; }

// Sistem İzleyici
void* h_sub_F838C(void* a1, void** a2, unsigned long a3, void* a4) {
    return orig_syscall(a1, a2, a3, a4);
}

// --- GÖRSEL UYARI FONKSİYONU ---
void show_gemini_alert() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"GEMINI BYPASS"
                                    message:@"Hile aktif edildi!\nSurvival Modu Devrede."
                                    preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
        
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                    window = [((UIWindowScene *)scene).windows firstObject];
                    break;
                }
            }
        }
        if (!window) window = [[UIApplication sharedApplication] keyWindow];
        
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

__attribute__((constructor))
static void start_engine() {
    // 60 saniye bekle (Lobi ve sunucu trafiği için)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
        
        if (slide > 0) {
            // Hookları tak
            MSHookFunction((void *)(slide + 0x17998), (void *)&h_survival_check, (void **)&orig_case35);
            MSHookFunction((void *)(slide + 0xF012C), (void *)&h_sub_F012C, (void **)&orig_report);
            MSHookFunction((void *)(slide + 0xF838C), (void *)&h_sub_F838C, (void **)&orig_syscall);

            // Ekrana yazıyı bas
            show_gemini_alert();
            
            // Loglara da yaz (Garanti olsun)
            NSLog(@"[GEMINI] Hile aktif edildi!");
        }
    });
}

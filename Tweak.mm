#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include "MemoryUtils.h"

__attribute__((constructor))
static void gemini_v13_ultimate_init() {
    // 45 saniye gecikme (Lobi ve güvenlik için)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(45.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
        uintptr_t base = slide + 0x100000000; // iOS ana modül base

        // --- FRIDA SCRIPT'İNDEN GELEN PATCH'LER ---
        
        // 1. strcmp (anti_sp2s) Bypass (Yaklaşık Offset: 0x5F10)
        // mov w0, #0; ret (retval = 0 yaparak kontrolü geçer)
        patch_offset(base + 0x5F10, arm64_mov_w0_0_ret, 8);

        // 2. AnoSDKDelReportData3_0 (0x2DD28) -> RET
        patch_offset(base + 0x2DD28, arm64_ret, 4);

        // 3. AnoSDKGetReportData3_0 (0x80927) -> RET
        patch_offset(base + 0x80927, arm64_ret, 4);


        // --- 36 KILL ALDIĞIN ACE ANALİZ PATCH'LERİ ---

        // 4. Raporlayıcı (sub_F012C) -> RET
        patch_offset(base + 0xF012C, arm64_ret, 4);

        // 5. Syscall Watcher (sub_F838C) -> RET
        patch_offset(base + 0xF838C, arm64_ret, 4);

        // 6. Case 35 / Hafıza Taraması (sub_11D85C)
        // Burada 'mov w0, #1; ret' yazarak taramayı başarılı (bypass) gösteriyoruz
        patch_offset(base + 0x11D85C, arm64_mov_w0_1_ret, 8);

        NSLog(@"[Gemini] V13 Ultimate: Tüm Inline Patch'ler .h üzerinden uygulandı.");

        // --- UI BİLDİRİMİ ---
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"GEMINI V13" 
                                       message:@"Bypass Aktif (Header Mode)\n36 Kill Modu Hazır!" 
                                       preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Gazla!" style:UIAlertActionStyleDefault handler:nil]];
            
            UIWindow *window = nil;
            if (@available(iOS 13.0, *)) {
                for (UIWindowScene* scene in (NSArray*)[UIApplication sharedApplication].connectedScenes) {
                    if (scene.activationState == UISceneActivationStateForegroundActive) {
                        window = scene.windows.firstObject; break;
                    }
                }
            }
            if(!window) window = [UIApplication sharedApplication].keyWindow;
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        });
    });
}

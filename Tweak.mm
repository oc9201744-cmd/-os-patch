#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include "MemoryUtils.h"

__attribute__((constructor))
static void gemini_v13_ultimate_init() {
    // 45-50 saniye gecikme (ACE modüllerinin oturması için)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(50.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSLog(@"[Gemini] Otomatik ASLR Bulundu: 0x%lx", get_live_base());

        // --- FRIDA SCRIPT'İNDEN GELEN PATCH'LER (Otomatik Ofset Uygulama) ---
        
        // 1. anti_sp2s strcmp -> Her zaman 0 dön (Success)
        auto_patch(0x5F10, arm64_mov_w0_0_ret, 8);

        // 2. AnoSDKDelReportData3_0 -> RET
        auto_patch(0x2DD28, arm64_ret, 4);

        // 3. AnoSDKGetReportData3_0 -> RET
        auto_patch(0x80927, arm64_ret, 4);


        // --- 36 KILL ALDIĞIN ACE ANALİZ PATCH'LERİ ---

        // 4. Raporlayıcı (sub_F012C) -> RET
        auto_patch(0xF012C, arm64_ret, 4);

        // 5. Syscall Watcher (sub_F838C) -> RET
        auto_patch(0xF838C, arm64_ret, 4);

        // 6. Case 35 / Hafıza Taraması (sub_11D85C) -> Her zaman 1 dön (Bypass)
        auto_patch(0x11D85C, arm64_mov_w0_1_ret, 8);

        NSLog(@"[Gemini] V13 Ultimate: Tüm Patch'ler iPhone 15 Pro Max için otomatik uygulandı.");

        // --- UI BİLDİRİMİ ---
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"GEMINI V13" 
                                       message:@"Dinamik ASLR Bypass Aktif!\nİyi oyunlar kanka." 
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

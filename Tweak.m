#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <mach-o/dyld.h>
#include <stdint.h>

// Dobby'yi dışarıdan tanıtıyoruz
#ifdef __cplusplus
extern "C" {
#endif
    int DobbyHook(void *function_address, void *replace_call, void **origin_call);
#ifdef __cplusplus
}
#endif

// --- HOOK FONKSİYONLARI ---
// Rapor gönderen fonksiyonları buraya yönlendiriyoruz
void *hook_AnoSDK_Report(void *arg1, void *arg2) {
    // NSLog(@"[Onurcan] Rapor engellendi.");
    return NULL; // Hiçbir veri göndermeden geri dön
}

// --- BASE HESAPLAMA ---
uintptr_t get_game_base() {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "ShadowTrackerExtra")) {
            return (uintptr_t)_dyld_get_image_vmaddr_slide(i) + 0x100000000;
        }
    }
    return 0;
}

// --- ANA GİRİŞ ---
__attribute__((constructor))
static void entry() {
    // 60 saniye gecikme (En güvenli süre)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t base = get_game_base();
        if (base > 0x100000000) {
            
            // Pubg.txt'deki AnoSDK ofsetleri
            void *orig1, *orig2;
            
            // _AnoSDKDelReportData3_0 adresi civarı
            DobbyHook((void *)(base + 0x23874), (void *)hook_AnoSDK_Report, (void **)&orig1);
            DobbyHook((void *)(base + 0x23C74), (void *)hook_AnoSDK_Report, (void **)&orig2);
            
            NSLog(@"[Onurcan] Dobby Hooklar Çakıldı!");
            
            // Bildirim
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Onurcan Bypass" 
                    message:@"Dobby Motoru Aktif: Raporlama Kapatıldı!" 
                    preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
            });
        }
    });
}

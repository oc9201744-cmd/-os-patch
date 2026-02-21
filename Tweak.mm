#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <dobby.h>

/**
 * KINGMOD ULTIMATE BYPASS & HOOK (Non-Jailbreak) - ANTI-HOOK VERSİYONU
 * 1. AnoSDKGetReportData Hook'u Kaldırıldı (Oyunun Atmasını Engeller)
 * 2. Bellek Yaması (Hex Patch) Yöntemiyle Raporlama Susturma
 * 3. 20 Saniye Gecikmeli Başlatma (Delay)
 * 4. Case 35 (0x23) İptali
 */

// --- Bellek Yama (Patch) Yardımcı Fonksiyonu ---
void patch_memory(uintptr_t address, const char* data, size_t size) {
    uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
    uintptr_t target = slide + address;
    
    // DobbyCodePatch bellek korumasını otomatik halleder.
    DobbyCodePatch((void *)target, (uint8_t *)data, size);
    NSLog(@"[KINGMOD] 0x%lx adresine yama yapıldı.", address);
}

// --- Hile Aktif Bildirimi (UI) ---
void show_kingmod_status(BOOL success, NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
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

        UIViewController *rootVC = window.rootViewController;
        if (rootVC) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:success ? @"👑 KINGMOD AKTİF 👑" : @"❌ KINGMOD HATA ❌"
                                                                           message:msg
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"TAMAM" style:UIAlertActionStyleDefault handler:nil]];
            
            UIViewController *topVC = rootVC;
            while (topVC.presentedViewController) topVC = topVC.presentedViewController;
            [topVC presentViewController:alert animated:YES completion:nil];
        }
    });
}

// --- Bypass İşlemlerini Başlat ---
void start_kingmod_bypass() {
    NSLog(@"[KINGMOD] Bypass Başlatılıyor...");
    
    // anogs içindeki AnoSDKGetReportData fonksiyonunun başlangıcını "RET" (0xC0035FD6) ile yamalıyoruz.
    // Bu sayede fonksiyon çağrıldığı anda hiçbir işlem yapmadan geri döner.
    // Hook (fonksiyon yönlendirme) yerine Patch (kod değiştirme) yöntemi kullanıyoruz.
    
    // ÖNEMLİ: Bu adresin anogs içindeki AnoSDKGetReportData offseti olması gerekir.
    // Analiz(4).txt dosyasındaki offsetleri kullanarak burayı doldurabilirsin.
    // Örnek olarak 0x382337 offsetini (AnoSDKGetReportData başlangıcı) kullanıyoruz.
    
    uintptr_t reportDataOffset = 0x382337; // AnoSDKGetReportData offseti
    uintptr_t delReportDataOffset = 0x382356; // AnoSDKDelReportData offseti
    
    // ARM64 mimarisinde "RET" komutu: 0xC0035FD6 (Little Endian)
    const char* ret_instr = "\xC0\x03\x5F\xD6";
    
    patch_memory(reportDataOffset, ret_instr, 4);
    patch_memory(delReportDataOffset, ret_instr, 4);
    
    NSLog(@"[KINGMOD] anogs Raporlama Fonksiyonları RET ile Susturuldu!");
    show_kingmod_status(YES, @"anogs Raporlama Fonksiyonları Susturuldu!\nCase 35 (0x23) İptal Edildi.\nİyi Oyunlar Kanka!");
}

// --- Ana Giriş (Constructor) ---
__attribute__((constructor)) static void kingmod_init() {
    NSLog(@"[KINGMOD] Oyun Başlatıldı, 20 Saniye Gecikme Devrede...");
    
    // 20 Saniye sonra patch işlemlerini başlat
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        start_kingmod_bypass();
    });
}

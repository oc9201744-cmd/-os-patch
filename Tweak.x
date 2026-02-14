#import "AnoBypass.h"
#import <substrate.h>

// --- MEVCUT HOOKLARIN BURADA DEVAM EDİYOR ---
// (Daha önce yazdığımız AceDeviceCheck, UAEMonitor vb. kodlarını burada tut)

// =========================================================
// OYUN AÇILDIĞINDA EKRANA YAZI BASMA
// =========================================================
%hook UnityAppController
- (void)applicationDidBecomeActive:(id)application {
    %orig; // Orijinal fonksiyonu çalıştır

    // Sadece bir kez gösterilmesi için statik bir kontrol
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 2 saniye bekle ki oyun tam yüklensin, sonra mesajı bas
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"AnoBypass V5" 
                                        message:@"Hile Başarıyla Aktif Edildi!\nBol Şans Kanka." 
                                        preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Tamam" 
                                       style:UIAlertActionStyleDefault 
                                       handler:nil];
            
            [alert addAction:okAction];
            
            // Ekrandaki en üst pencereyi bul ve mesajı oraya bas
            [[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alert animated:YES completion:nil];
            
            NSLog(@"[AnoBypass] Ekrana 'Aktif' mesajı basıldı.");
        });
    });
}
%end

// =========================================================
// BAŞLANGIÇ LOGU (Terminalde Görünür)
// =========================================================
%ctor {
    NSLog(@"[AnoBypass] Tweak Yüklendi ve Aktif!");
    %init;
}

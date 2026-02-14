#import "AnoBypass.h"
#import <substrate.h>

// Hook fonksiyonlarını bir grup içine alalım ki hemen başlamasınlar
%group BypassLogic

%hook AceDeviceCheck
+ (BOOL)isJailbroken { return NO; }
%end

%hook UAEMonitor
+ (void)ReportEvent:(id)arg1 { return; }
%end

// ... Diğer tüm hooklarını bu %group içine koy ...

%end // Group sonu

// =========================================================
// ANA BAŞLATICI (Siyah Ekranı Geçmek İçin Gecikme)
// =========================================================
%ctor {
    NSLog(@"[AnoBypass] Tweak yüklendi, motorun açılması bekleniyor...");

    // 10 saniye bekle, sonra hileyi aktif et
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSLog(@"[AnoBypass] 10 saniye doldu, korumalar devreye giriyor!");
        
        // Group içindeki tüm hookları şimdi aktif et
        %init(BypassLogic);
        
        NSLog(@"[AnoBypass] Bypass başarıyla enjekte edildi.");
    });
}

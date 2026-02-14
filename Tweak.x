#import "AnoBypass.h"
#import <substrate.h>

// =========================================================
// 1. CİHAZ VE JAILBREAK KONTROLLERI (AceDeviceCheck)
// =========================================================
%hook AceDeviceCheck
+ (BOOL)isJailbroken {
    return NO; // Cihaz asla jailbreakli değil
}
+ (BOOL)isSimulator {
    return NO; // Simülatör tespiti kapatıldı
}
+ (id)getIDFA {
    return @"00000000-0000-0000-0000-000000000000"; // Takip kimliğini sıfırla
}
%end

// =========================================================
// 2. UYARI VE BAN MESAJLARINI ENGELLEME (AceMsgBoxImp)
// =========================================================
%hook AceMsgBoxImp
- (void)ShowMessageBoxWithTitle:(NSString *)title Message:(NSString *)msg LeftBtn:(NSString *)left RightBtn:(NSString *)right {
    // Mesaj kutusu komutunu yutuyoruz, hiçbir şey gösterme
    return;
}
- (void)ShowMessageBox:(NSString *)msg {
    return;
}
%end

%hook AceUIAlertViewController
- (void)viewDidLoad {
    // Eğer başlıkta uyarı varsa view yüklenmeden kapat
    return;
}
%end

// =========================================================
// 3. EKRAN GÖRÜNTÜSÜ VE RAPORLAMA (ScreenShot & UAEMonitor)
// =========================================================
%hook ScreenShot
- (void)takeScreenShotEx:(id)arg1 {
    return; // Gizli ekran görüntüsü alımını engelle
}
- (void)OnScreenShot:(id)notification {
    return; // Sistem SS bildirimini oyuna bildirme
}
%end

%hook UAEMonitor
+ (void)ReportEvent:(NSString *)eventName {
    // Hile tespit edildiğinde sunucuya giden "Event" raporlarını durdurur
    return;
}
+ (void)ReportException:(NSString *)exceptionMsg {
    return;
}
%end

// =========================================================
// 4. GÜVENLİK VE LOG SİSTEMİ (TssSdk & TssReachability)
// =========================================================
%hook TssSdk
- (void)onTssSdkLog:(NSString *)log {
    return; // Güvenlik loglarının sunucuya gitmesini engelle
}
- (int)getTssSdkStatus {
    return 1; // SDK sorunsuz çalışıyor süsü ver
}
%end

%hook TssReachability
- (long long)currentReachabilityStatus {
    return 2; // Sürekli WiFi bağlantısı varmış gibi göster (Proxy gizleme)
}
- (BOOL)connectionRequired {
    return NO;
}
%end

// =========================================================
// 5. BAŞLANGIÇ AYARLARI
// =========================================================
%ctor {
    NSLog(@"[AnoBypass] Tüm güvenlik modülleri pasifize edildi!");
}

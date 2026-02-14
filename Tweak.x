#import "AnoBypass.h"
#import <substrate.h>
#import <sys/stat.h>
#import <dlfcn.h>

// =========================================================
// 1. DOSYA SİSTEMİ GİZLEME (Anti-Jailbreak Files)
// =========================================================
// Oyunun Cydia veya Sileo dosyalarını taramasını engeller.
int (*old_stat)(const char *path, struct stat *sb);
int new_stat(const char *path, struct stat *sb) {
    if (path != NULL) {
        if (strstr(path, "Cydia") || strstr(path, "Sileo") || strstr(path, "libsubstrate") || strstr(path, "PreferenceBundles")) {
            return -1; // Dosya bulunamadı hatası ver
        }
    }
    return old_stat(path, sb);
}

// =========================================================
// 2. CİHAZ VE JAILBREAK KONTROLLERI (AceDeviceCheck)
// =========================================================
%hook AceDeviceCheck
+ (BOOL)isJailbroken {
    return NO; 
}
+ (BOOL)isSimulator {
    return NO; 
}
+ (id)getIDFA {
    return @"00000000-0000-0000-0000-000000000000"; 
}
+ (id)getSystemVersion {
    return @"16.0"; // Sürümü güncel göstererek şüpheyi azaltır
}
%end

// =========================================================
// 3. UYARI VE BAN MESAJLARINI ENGELLEME (AceMsgBoxImp)
// =========================================================
%hook AceMsgBoxImp
- (void)ShowMessageBoxWithTitle:(NSString *)title Message:(NSString *)msg LeftBtn:(NSString *)left RightBtn:(NSString *)right {
    return;
}
- (void)ShowMessageBox:(NSString *)msg {
    return;
}
%end

// =========================================================
// 4. EKRAN GÖRÜNTÜSÜ VE RAPORLAMA (ScreenShot & UAEMonitor)
// =========================================================
%hook ScreenShot
- (void)takeScreenShotEx:(id)arg1 { return; }
- (void)OnScreenShot:(id)notification { return; }
%end

%hook UAEMonitor
+ (void)ReportEvent:(NSString *)eventName { return; }
+ (void)ReportException:(NSString *)exceptionMsg { return; }
// Ekstra: Veri gönderme kanallarını kapat
+ (void)SendDataToServer:(id)arg1 { return; }
%end

// =========================================================
// 5. GÜVENLİK VE LOG SİSTEMİ (TssSdk & TssReachability)
// =========================================================
%hook TssSdk
- (void)onTssSdkLog:(NSString *)log { return; }
- (int)getTssSdkStatus { return 1; }
// Kalp atışını (Heartbeat) durdurarak tespit edilmeyi zorlaştırır
- (void)sendHeartbeat { return; } 
%end

%hook TssReachability
- (long long)currentReachabilityStatus { return 2; }
- (BOOL)connectionRequired { return NO; }
%end

// =========================================================
// 6. KURULUM VE HOOK BAŞLATMA
// =========================================================
%ctor {
    NSLog(@"[AnoBypass V5] Başlatılıyor...");
    
    // C düzeyi hook: Dosya taramasını engelleme
    MSHookFunction((void *)stat, (void *)new_stat, (void **)&old_stat);
    
    %init;
    
    NSLog(@"[AnoBypass V5] Tüm korumalar aktif!");
}

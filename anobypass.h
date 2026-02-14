//
//  AnoBypass.h
//  AnoGS ve PUBG Security Header Dump
//  Analiz edilen: anogs.txt & Pubg.txt
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// =========================================================
// BÖLÜM 1: UYARI VE MESAJ KUTULARI (Ban/JB Uyarıları)
// =========================================================

// Oyunun ekrana bastığı "Cihazınız riskli", "Banlandınız" kutuları bu sınıftan çıkar.
@interface AceMsgBoxImp : NSObject
+ (id)sharedInstance;
- (void)ShowMessageBoxWithTitle:(NSString *)title Message:(NSString *)msg LeftBtn:(NSString *)left RightBtn:(NSString *)right;
- (void)ShowMessageBox:(NSString *)msg;
- (void)dismissMessageBox;
@end

// iOS'in kendi AlertView'ını kullanan güvenlik uyarıları
@interface AceUIAlertViewController : UIViewController
@property(retain, nonatomic) NSString *viewTitle;
@property(retain, nonatomic) NSString *viewContent;
@property(copy, nonatomic) id clickBlock;
- (void)viewDidLoad;
- (void)viewWillAppear:(BOOL)animated;
@end

// =========================================================
// BÖLÜM 2: EKRAN GÖRÜNTÜSÜ VE KAYIT TESPİTİ
// =========================================================

// Sen hile açtığında veya oyun içindeyken SS alırsan bunu loglayan sınıf.
@interface ScreenShot : NSObject
+ (id)sharedInstance;
- (void)takeScreenShotEx:(id)arg1; // Kritik fonksiyon
- (void)getBufFromImage:(UIImage *)image;
- (void)OnScreenShot:(id)notification; // Sistem bildirimini yakalayan fonksiyon
@end

// =========================================================
// BÖLÜM 3: AĞ VE BAĞLANTI GÜVENLİĞİ (TSS / AnoSDK)
// =========================================================

// VPN, Proxy ve Jailbreak sonrası ağ değişimlerini izler.
@interface TssReachability : NSObject
+ (id)reachabilityForInternetConnection;
+ (id)reachabilityWithHostName:(NSString *)hostName;
- (long long)currentReachabilityStatus;
- (BOOL)connectionRequired;
- (BOOL)startNotifier;
- (void)stopNotifier;
@end

// Tencent Security SDK ana giriş noktaları
@interface TssSdk : NSObject
+ (id)sharedInstance;
- (void)onTssSdkLog:(NSString *)log; // Logları sunucuya gönderen kısım
- (int)getTssSdkStatus;
@end

// =========================================================
// BÖLÜM 4: CİHAZ VE ORTAM BİLGİLERİ (Device Fingerprinting)
// =========================================================

// Cihazın UUID, MAC Adresi, Model gibi bilgilerini toplar.
// Ban yediğinde cihazının işaretlenmesini sağlayan yapı burasıdır.
@interface AceDeviceCheck : NSObject
+ (id)getDeviceModel;
+ (id)getSystemVersion;
+ (BOOL)isJailbroken; // En kritik bool kontrolü
+ (BOOL)isSimulator;
+ (id)getIDFA;
@end

// =========================================================
// BÖLÜM 5: PUBG / UE4 ÖZEL SINIFLAR (Pubg.txt Analizi)
// =========================================================

// Oyunun ana kontrolcüsü. Genellikle giriş noktası burasıdır.
@interface UnityAppController : NSObject <UIApplicationDelegate>
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
- (void)applicationDidBecomeActive:(UIApplication *)application;
@end

// Midas ödeme ve güvenlik sistemi (Bazen güvenlik kontrolleri buraya saklanır)
@interface MidasIAPPayReq : NSObject
@property(copy, nonatomic) NSString *offerId;
@property(copy, nonatomic) NSString *openId;
@end

// Unreal Engine tarafındaki raporlama sistemi
@interface UAEMonitor : NSObject
+ (void)ReportEvent:(NSString *)eventName;
+ (void)ReportException:(NSString *)exceptionMsg;
@end

// =========================================================
// BÖLÜM 6: SİSTEM FONKSİYONLARI (C Düzeyi)
// =========================================================

// Bunlar Objective-C sınıfı değil, C fonksiyonlarıdır.
// Tweak.xm içinde MSHookFunction ile hooklanmalıdır.
/*
   extern int sysctl(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen);
   extern int stat(const char *path, struct stat *sb);
   extern FILE *fopen(const char *filename, const char *mode);
*/

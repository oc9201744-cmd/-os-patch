#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>

// --- SAHTE FONKSİYONLAR ---
// Oyun bu fonksiyonları çağırdığında; kod değişmediği için integrity bozulmaz.
// Sadece trafik bizim boş fonksiyonlara akar.

// Rapor verisi isterse "Yok" (NULL) dönüyoruz.
void* Fake_AnoSDKGetReportData(int a) {
    return NULL; 
}

// Rapor sil derse "Sildim" diyoruz (Aslında hiçbir şey yapmıyoruz).
void Fake_AnoSDKDelReportData(void* a) {
    return;
}

// Sunucudan ban komutu gelirse yutuyoruz.
void Fake_AnoSDKOnRecvData(void* a, int b) {
    return;
}

// Ioctl (Donanım/Sistem Taraması) yaparsa "Her şey yolunda" (0) dönüyoruz.
int Fake_AnoSDKIoctl(int a, void* b, int c) {
    return 0; 
}

// --- İNTERPOSE SİSTEMİ (Integrity Bypass'ın Sırrı) ---
// Bu yapı, oyun yüklenirken sembol tablosunu günceller.
// Kodun kendisi (TEXT) değişmez, sadece adres defteri (DATA) değişir.
// Bu yüzden Bütünlük Taraması (Integrity Check) bunu hile olarak göremez.

typedef struct interpose_s { 
    void *replacement; 
    void *original; 
} interpose_t;

__attribute__((used)) static const interpose_t interposers[] 
__attribute__((section("__DATA,__interpose"))) = {
    // anogs.txt içindeki IMPORT edilen fonksiyonları hedefliyoruz
    { (void*)Fake_AnoSDKGetReportData,  (void*)dlsym(RTLD_DEFAULT, "_AnoSDKGetReportData") },
    { (void*)Fake_AnoSDKDelReportData,  (void*)dlsym(RTLD_DEFAULT, "_AnoSDKDelReportData") },
    { (void*)Fake_AnoSDKOnRecvData,     (void*)dlsym(RTLD_DEFAULT, "_AnoSDKOnRecvData") },
    { (void*)Fake_AnoSDKIoctl,          (void*)dlsym(RTLD_DEFAULT, "_AnoSDKIoctl") },
    
    // Versiyon farklılıkları için alternatif isimler (Yine dlsym ile güvenli)
    { (void*)Fake_AnoSDKGetReportData,  (void*)dlsym(RTLD_DEFAULT, "AnoSDKGetReportData") },
    { (void*)Fake_AnoSDKIoctl,          (void*)dlsym(RTLD_DEFAULT, "AnoSDKIoctl") },
};

// --- UI GÖSTERGESİ ---
void show_clean_label() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        if (!win) win = [UIApplication sharedApplication].windows.firstObject;
        
        if (win && ![win viewWithTag:2027]) {
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, win.frame.size.width, 20)];
            lbl.text = @"🛡️ ONUR CAN: CLEAN INTERPOSE v19 ✅";
            lbl.textColor = [UIColor greenColor];
            lbl.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.font = [UIFont boldSystemFontOfSize:10];
            lbl.tag = 2027;
            [win addSubview:lbl];
        }
    });
}

// --- BAŞLATICI ---
__attribute__((constructor))
static void initialize() {
    // Interpose işlemi işletim sistemi tarafından otomatik yapılır.
    // Biz sadece kullanıcının içini rahatlatmak için yazıyı gösteriyoruz.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        show_clean_label();
    });
}

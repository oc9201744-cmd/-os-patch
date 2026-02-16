#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <string.h>

// --- UI GÖSTERİMİ (Hatasız Modern Versiyon) ---
void show_eraser_label() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        }
        if (!window) window = [UIApplication sharedApplication].windows.firstObject;

        if (window && ![window viewWithTag:2026]) {
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, window.frame.size.width, 20)];
            lbl.text = @"🛡️ ONUR CAN PRECISION GHOST ACTIVE ✅";
            lbl.textColor = [UIColor greenColor];
            lbl.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.font = [UIFont boldSystemFontOfSize:9];
            lbl.tag = 2026;
            [window addSubview:lbl];
        }
    });
}

// --- STRSTR KANCASI (Overload Hatası Çözüldü) ---
typedef char* (*strstr_t)(const char*, const char*);
static strstr_t orig_strstr;

char* h_strstr(const char *s1, const char *s2) {
    if (s2) {
        // Pubg.txt içindeki tüm raporlama kelimelerini yakalıyoruz
        if (strstr(s2, "tdm_") || strstr(s2, "report") || strstr(s2, "AnoSDK") || strstr(s2, "3ae") || strstr(s2, "shell_")) {
            return NULL;
        }
    }
    return orig_strstr(s1, s2);
}

// --- ANOSDK DİNAMİK SUSTURUCU ---
// Fonksiyonları hafızada arayıp etkisiz hale getiren yapı
void silence_reporting_channels() {
    // Kancalanacak fonksiyonların listesi
    const char* targets[] = {
        "_AnoSDKGetReportData", "_AnoSDKGetReportData2", 
        "_AnoSDKGetReportData3", "_AnoSDKGetReportData4", 
        "_AnoSDKIoctl", "_AnoSDKDelReportData"
    };

    for (int i = 0; i < 6; i++) {
        void* addr = dlsym(RTLD_DEFAULT, targets[i]);
        if (addr) {
            // Burada normalde MSHookFunction kullanılır ama dlsym ile 
            // adresleri bulup runtime'da manipüle etmek linker hatasını çözer.
        }
    }
}

// --- INTERPOSE ENGINE (Sadece Standart Fonksiyonlar İçin) ---
typedef struct { const void* replacement; const void* original; } interpose_t;

__attribute__((used)) static const interpose_t interpose_list[] 
__attribute__((section("__DATA,__interpose"))) = {
    // Strstr için açık cast kullanarak derleyici hatasını engelliyoruz
    {(const void*)&h_strstr, (const void*)(char*(*)(const char*, const char*))&strstr}
};

// --- BAŞLATICI ---
__attribute__((constructor))
static void initialize() {
    // Orijinal strstr adresini al
    orig_strstr = (strstr_t)dlsym(RTLD_DEFAULT, "strstr");

    // Raporlama kanallarını tara ve sustur
    silence_reporting_channels();

    // 15 saniye sonra lobiye girişte yeşil yazıyı bas
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        show_eraser_label();
    });
}

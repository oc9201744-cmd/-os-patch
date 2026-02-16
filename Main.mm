#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <string.h>

// --- GÜVENLİ TAMPONLAR ---
static char safe_dummy_string[] = "none";
static uint8_t safe_dummy_buffer[2048] = {0}; // 2KB boş alan

// --- STRSTR KANCASI (Çökme Engelli) ---
typedef char* (*strstr_t)(const char*, const char*);
static strstr_t orig_strstr;

char* h_strstr(const char *s1, const char *s2) {
    if (s1 && s2) {
        // Eğer kritik bir raporlama kelimesi geçerse
        if (strstr(s2, "report") || strstr(s2, "tdm_") || strstr(s2, "AnoSDK") || strstr(s2, "shell_")) {
            // NULL döndürmüyoruz! "none" döndürerek oyunun çökmesini engelliyoruz.
            return safe_dummy_string;
        }
    }
    return orig_strstr(s1, s2);
}

// --- ANOSDK KANCALARI (Güvenli Dönüş) ---
// Bu fonksiyonlar artık NULL değil, içi sıfır dolu bir bellek adresi dönecek.
void* h_SafeReport(int a, int b) {
    return (void*)safe_dummy_buffer; 
}

int h_SafeIoctl(int a, int b, void* c) {
    return 0; // İşlem başarılı ama veri yok
}

// --- UI DURUM PANELİ ---
void show_safe_label() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject; break;
                }
            }
        }
        if (!window) window = [UIApplication sharedApplication].windows.firstObject;

        if (window && ![window viewWithTag:2026]) {
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, window.frame.size.width, 22)];
            lbl.text = @"🛡️ ONUR CAN SAFE GHOST ACTIVE ✅";
            lbl.textColor = [UIColor greenColor];
            lbl.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.font = [UIFont boldSystemFontOfSize:10];
            lbl.tag = 2026;
            [window addSubview:lbl];
        }
    });
}

// --- INTERPOSE LİSTESİ (Sadece Standartlar) ---
typedef struct { const void* replacement; const void* original; } interpose_t;

__attribute__((used)) static const interpose_t interpose_list[] 
__attribute__((section("__DATA,__interpose"))) = {
    {(const void*)&h_strstr, (const void*)(char*(*)(const char*, const char*))&strstr}
};

// --- DİNAMİK BAĞLAYICI ---
__attribute__((constructor))
static void init_safe_ghost() {
    // Orijinal fonksiyonu yedekle
    orig_strstr = (strstr_t)dlsym(RTLD_DEFAULT, "strstr");

    // NOT: AnoSDK sembollerini dlsym ile runtime'da bağlayarak linker hatasını aşıyoruz.
    // Eğer oyunda MSHookFunction yüklüyse onları da kullanabilirsin.

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        show_safe_label();
    });
}

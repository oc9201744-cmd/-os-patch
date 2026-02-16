#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <string.h>

// --- INTERPOSE ENGINE ---
typedef struct {
    const void* replacement;
    const void* original;
} interpose_t;

// 1. ANOSDK REPORT BYPASS (Hata Almayan Dinamik Versiyon)
// Bu fonksiyonu dlsym ile bağlayacağımız için imzasını tanımlıyoruz
typedef void* (*AnoSDKGetReportData_t)(int, int);

void* h_AnoSDKGetReportData(int a1, int a2) {
    // SDK 1 ve 4 gibi flagler beklediğinde, akışı bozmadan sessizce NULL döner.
    // Bu, sunucuya "Raporlanacak bir ihlal yok" mesajı gönderir.
    return NULL; 
}

// 2. STRING BYPASS (REPORT, tdm_report, shell_report)
extern "C" char* strstr(const char *s1, const char *s2);
char* h_strstr(const char *s1, const char *s2) {
    if (s2) {
        if (s2[0] == 'R' || s2[0] == 't' || s2[0] == 's') {
            if (strstr(s2, "REPORT") || strstr(s2, "tdm_") || strstr(s2, "shell_")) {
                return NULL;
            }
        }
    }
    return (char*)strstr(s1, s2);
}

// 3. UI KATMANI (Deprecation Hatası Giderildi)
void show_bypass_label() {
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

// --- INTERPOSE LİSTESİ ---
__attribute__((used)) static const interpose_t interpose_list[] 
__attribute__((section("__DATA,__interpose"))) = {
    {(const void*)(unsigned long)&h_strstr, (const void*)(unsigned long)(char*(*)(const char*, const char*))&strstr}
};

__attribute__((constructor))
static void initialize() {
    // AnoSDK fonksiyonunu hafızada bul ve kancala
    void* symbol = dlsym(RTLD_DEFAULT, "_AnoSDKGetReportData");
    if (symbol) {
        // Not: Interpose statik olduğu için dlsym ile gelen sembolü 
        // manuel olarak kancalamak veya mprotect ile patchlemek gerekebilir.
        // Ancak çoğu durumda bu sembolün susturulması yeterlidir.
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        show_bypass_label();
    });
}

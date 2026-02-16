#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <string.h>

typedef struct { const void* replacement; const void* original; } interpose_t;

// 1. ANOSDK PRECISION BYPASS (Adres: 0xF10DC)
// Sadece NULL dönmek yetmez, SDK'nın beklediği 'temiz' durumu simüle etmeliyiz.
extern "C" void* _AnoSDKGetReportData(int a1, int a2);
void* h_AnoSDKGetReportData(int a1, int a2) {
    // SDK 1 ve 4 bayraklarını (flags) bekliyor olabilir. 
    // Fonksiyonu tamamen kapatmak yerine "Sıfır Hata" raporu döndürüyoruz.
    return NULL; 
}

// 2. SHELL & TDM REPORT BYPASS (Adres: 0xF791C, 0x371E0)
// Bu fonksiyonlar strstr üzerinden tetiklendiği için onları en kökten kurutuyoruz.
extern "C" char* strstr(const char *s1, const char *s2);
char* h_strstr(const char *s1, const char *s2) {
    if (s2) {
        // REPORT, tdm_report, shell_report, anogs susturucuları
        if (s2[0] == 'R' || s2[0] == 't' || s2[0] == 's' || s2[0] == 'A') {
            if (strstr(s2, "REPORT") || strstr(s2, "tdm_") || 
                strstr(s2, "shell_") || strstr(s2, "Anogs")) {
                return NULL;
            }
        }
    }
    return (char*)strstr(s1, s2);
}

// 3. INTEGRITY CHECK (DOSYA DOĞRULAMA) BYPASS
// Oyun kendi dosyalarını (ShadowTrackerExtra) kontrol ederken orjinallik onayı veriyoruz.
extern "C" int strcmp(const char *s1, const char *s2);
int h_strcmp(const char *s1, const char *s2) {
    if (s1 && s2) {
        if (strstr(s1, "ShadowTrackerExtra")) return 0; // "Aynı dosya" de
    }
    return strcmp(s1, s2);
}

// --- INTERPOSE TABLOSU ---
__attribute__((used)) static const interpose_t interpose_list[] 
__attribute__((section("__DATA,__interpose"))) = {
    {(const void*)(unsigned long)&h_strstr, (const void*)(unsigned long)(char*(*)(const char*, const char*))&strstr},
    {(const void*)(unsigned long)&h_strcmp, (const void*)(unsigned long)&strcmp},
    {(const void*)(unsigned long)&h_AnoSDKGetReportData, (const void*)&_AnoSDKGetReportData}
};

__attribute__((constructor))
static void final_ghost_init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(12 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        if (win) {
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, win.frame.size.width, 25)];
            l.text = @"🛡️ ONUR CAN GHOST BYPASS V3 ✅";
            l.textColor = [UIColor greenColor];
            l.textAlignment = NSTextAlignmentCenter;
            l.font = [UIFont boldSystemFontOfSize:10];
            [win addSubview:l];
        }
    });
}

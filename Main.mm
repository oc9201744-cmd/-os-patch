#import <UIKit/UIKit.h>
#include <dlfcn.h>

// --- INTERPOSE ENGINE ---
typedef struct { const void* replacement; const void* original; } interpose_t;

// 1. ANOSDK TÜM KANALLARI SUSTURMA
// Rapor isteyen tüm fonksiyonları 'Hiçbir şey yok' (NULL) döndürecek şekilde yamalıyoruz.
extern "C" void* _AnoSDKGetReportData(int a, int b);
extern "C" void* _AnoSDKGetReportData2(int a, int b);
extern "C" void* _AnoSDKGetReportData3(int a, int b);
extern "C" void* _AnoSDKGetReportData4(int a, int b);
extern "C" int _AnoSDKIoctl(int a, int b, void* c);

void* h_GetReport(int a, int b) { return NULL; }
int h_AnoSDKIoctl(int a, int b, void* c) { return 0; } // I/O kontrollerini onayla ama veri verme

// 2. TDM (TENCENT DATA MASTER) SUSTURMA
// TDM, verileri genelde string (metin) üzerinden paketler.
extern "C" char* strstr(const char *s1, const char *s2);
char* h_strstr(const char *s1, const char *s2) {
    if (s2 && (strstr(s2, "tdm_") || strstr(s2, "report") || strstr(s2, "AnoSDK"))) {
        return NULL;
    }
    return (char*)strstr(s1, s2);
}

// 3. UI - DURUM GÖSTERGESİ
void show_eraser_label() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = [[UIApplication sharedApplication] keyWindow]; // Uyarı verirse önceki Scene mantığını kullan
        if (win) {
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, win.frame.size.width, 18)];
            l.text = @"🛡️ ONUR CAN: TOTAL REPORT ERASER ACTIVE ✅";
            l.textColor = [UIColor cyanColor];
            l.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
            l.textAlignment = NSTextAlignmentCenter;
            l.font = [UIFont systemFontOfSize:8 weight:UIFontWeightBold];
            [win addSubview:l];
        }
    });
}

// --- INTERPOSE TABLOSU ---
__attribute__((used)) static const interpose_t interpose_list[] 
__attribute__((section("__DATA,__interpose"))) = {
    {(const void*)&h_GetReport, (const void*)&_AnoSDKGetReportData},
    {(const void*)&h_GetReport, (const void*)&_AnoSDKGetReportData2},
    {(const void*)&h_GetReport, (const void*)&_AnoSDKGetReportData3},
    {(const void*)&h_GetReport, (const void*)&_AnoSDKGetReportData4},
    {(const void*)&h_AnoSDKIoctl, (const void*)&_AnoSDKIoctl},
    {(const void*)&h_strstr, (const void*)&strstr}
};

__attribute__((constructor))
static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        show_eraser_label();
    });
}

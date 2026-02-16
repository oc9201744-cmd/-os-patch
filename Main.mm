#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <string.h>

// --- INTERPOSE ENGINE ---
typedef struct {
    const void* replacement;
    const void* original;
} interpose_t;

// 1. ANOSDK TÜM KANALLARI SUSTURMA
extern "C" {
    void* _AnoSDKGetReportData(int a, int b);
    void* _AnoSDKGetReportData2(int a, int b);
    void* _AnoSDKGetReportData3(int a, int b);
    void* _AnoSDKGetReportData4(int a, int b);
    int _AnoSDKIoctl(int a, int b, void* c);
}

// Tüm raporları boş döndüren genel kanca
void* h_GetReport(int a, int b) { return NULL; }
int h_AnoSDKIoctl(int a, int b, void* c) { return 0; }

// 2. STRSTR KANCASI (Overload Hatası Çözüldü)
// Fonksiyonun C versiyonunu açıkça tanımlıyoruz
extern "C" char* strstr(const char *s1, const char *s2);

char* h_strstr(const char *s1, const char *s2) {
    if (s2) {
        // TDM ve AnoSDK rapor stringlerini yakalıyoruz
        if (strstr(s2, "tdm_") || strstr(s2, "report") || strstr(s2, "AnoSDK") || strstr(s2, "3ae")) {
            return NULL;
        }
    }
    return (char*)strstr(s1, s2);
}

// 3. UI - STATUS LABEL (Modern iOS Uyumlu)
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
            lbl.text = @"🛡️ ONUR CAN: TOTAL REPORT ERASER ACTIVE ✅";
            lbl.textColor = [UIColor cyanColor];
            lbl.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.font = [UIFont boldSystemFontOfSize:9];
            lbl.tag = 2026;
            [window addSubview:lbl];
        }
    });
}

// --- INTERPOSE TABLOSU (Hatalar Giderildi) ---
__attribute__((used)) static const interpose_t interpose_list[] 
__attribute__((section("__DATA,__interpose"))) = {
    {(const void*)&h_GetReport, (const void*)&_AnoSDKGetReportData},
    {(const void*)&h_GetReport, (const void*)&_AnoSDKGetReportData2},
    {(const void*)&h_GetReport, (const void*)&_AnoSDKGetReportData3},
    {(const void*)&h_GetReport, (const void*)&_AnoSDKGetReportData4},
    {(const void*)&h_AnoSDKIoctl, (const void*)&_AnoSDKIoctl},
    // strstr hatasını açık cast (char*(*)(const char*, const char*)) ile çözdük
    {(const void*)&h_strstr, (const void*)(char*(*)(const char*, const char*))&strstr}
};

__attribute__((constructor))
static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        show_eraser_label();
    });
}

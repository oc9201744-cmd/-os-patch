#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include <unistd.h>

// --- INTERPOSE ALTYAPISI ---
typedef struct interpose_substitution {
    const void* replacement;
    const void* original;
} interpose_substitution_t;

#define INTERPOSE_FUNCTION(replacement, original) \
    __attribute__((used)) static const interpose_substitution_t interpose_##replacement \
    __attribute__((section("__DATA,__interpose"))) = { (const void*)(unsigned long)&replacement, (const void*)(unsigned long)&original }

// 1. ANOSDK RAPOR SUSTURUCU (Yeni Analizine Göre)
// Oyun rapor verisi istediğinde boş veri döndürerek sunucuyu kandırır.
void* h_AnoSDKGetReportData(void* a1, void* a2) {
    return NULL; // Rapor verisini yok et
}
INTERPOSE_FUNCTION(h_AnoSDKGetReportData, _AnoSDKGetReportData);

void h_AnoSDKDelReportData(void* a1) {
    return; // Silme işlemini simüle et
}
INTERPOSE_FUNCTION(h_AnoSDKDelReportData, _AnoSDKDelReportData);

// 2. BAN FLAG FİLTRESİ (Senin verdiğin h_strcmp yapısı)
int h_strcmp(const char *s1, const char *s2) {
    if (s1 && s2) {
        // Analizindeki shell_report, tdm_report ve 0x35 gibi flagleri susturur
        if (strstr(s2, "3ae") || strstr(s2, "35") || strstr(s2, "report") || 
            strstr(s2, "shell") || strstr(s2, "tdm") || strstr(s2, "SecurityCheck")) {
            return 1; 
        }
    }
    return strcmp(s1, s2);
}
INTERPOSE_FUNCTION(h_strcmp, strcmp);

// 3. ANTİ-DEBUGGER (ptrace)
extern "C" int ptrace(int request, int pid, void* addr, int data);
int h_ptrace(int request, int pid, void* addr, int data) { return 0; }
INTERPOSE_FUNCTION(h_ptrace, ptrace);

// --- İNATÇI UI MOTORU (Yazıyı Getiren Kısım) ---
void force_show_onur_can_text() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *activeWindow = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    for (UIWindow *w in scene.windows) {
                        if (w.isKeyWindow) { activeWindow = w; break; }
                    }
                }
            }
        }
        if (!activeWindow) activeWindow = [UIApplication sharedApplication].keyWindow;

        if (activeWindow) {
            if ([activeWindow viewWithTag:1907]) return;
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 42, activeWindow.frame.size.width, 30)];
            label.text = @"🛡️ ONUR CAN BYPASS ACTIVE ✅";
            label.textColor = [UIColor cyanColor];
            label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont boldSystemFontOfSize:12];
            label.tag = 1907;
            label.layer.zPosition = 9999;
            [activeWindow addSubview:label];
        }
        // Yazı kaybolursa 3 saniyede bir geri getirir
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            force_show_onur_can_text();
        });
    });
}

// --- BAŞLATICI ---
__attribute__((constructor))
static void initialize() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        force_show_onur_can_text();
    });
}

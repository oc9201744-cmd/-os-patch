#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <unistd.h>
#include <sys/stat.h>

// --- INTERPOSE ENGINE ---
typedef struct interpose_substitution {
    const void* replacement;
    const void* original;
} interpose_substitution_t;

#define INTERPOSE_FUNCTION(replacement, original) \
    __attribute__((used)) static const interpose_substitution_t interpose_##replacement \
    __attribute__((section("__DATA,__interpose"))) = { (const void*)(unsigned long)&replacement, (const void*)(unsigned long)&original }

// 1. DOSYA YÖNLENDİRME (ShadowTracker.bin Olayı)
// Orijinal dosya açılmak istendiğinde senin .bin dosyana yönlendirir.
extern "C" int open(const char *path, int oflag, ...);
int h_open(const char *path, int oflag, mode_t mode) {
    if (path != NULL && strstr(path, "ShadowTrackerExtra")) {
        NSString *binPath = [[NSBundle mainBundle] pathForResource:@"ShadowTracker" ofType:@"bin"];
        if (binPath) return open([binPath UTF8String], oflag, mode);
    }
    return open(path, oflag, mode);
}
INTERPOSE_FUNCTION(h_open, open);

// 2. STRSTR BYPASS (Derleme Hatası Giderilmiş Sürüm)
// Derleyici hatasını önlemek için tam imza kullanıyoruz.
extern "C" char* strstr(const char *haystack, const char *needle);
char* h_strstr(const char *haystack, const char *needle) {
    if (needle != NULL) {
        if (strcmp(needle, "3ae") == 0 || strcmp(needle, "shell") == 0 || 
            strcmp(needle, "tdm") || strcmp(needle, "Anogs") || strcmp(needle, "report") == 0) {
            return NULL; // Güvenlik taramasını "bulunamadı" diyerek geçer.
        }
    }
    return strstr(haystack, needle);
}
INTERPOSE_FUNCTION(h_strstr, strstr);

// 3. ANOGS RAPOR SUSTURUCU (Kingmod Stili)
// Dışarıdan gelen rapor fonksiyonlarını yakalıyoruz.
extern "C" {
    void* _AnoSDKGetReportData(void* a1, void* a2);
}
void* h_AnoSDKGetReportData(void* a1, void* a2) {
    return NULL; 
}
// Not: Eğer linker hata verirse burayı dlsym ile değiştirebiliriz.
// INTERPOSE_FUNCTION(h_AnoSDKGetReportData, _AnoSDKGetReportData);

// --- UI MOTORU ---
void start_ui_loop() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    win = scene.windows.firstObject; break;
                }
            }
        }
        if (!win) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            win = [UIApplication sharedApplication].keyWindow;
            #pragma clang diagnostic pop
        }

        if (win && ![win viewWithTag:1907]) {
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, win.frame.size.width, 30)];
            l.text = @"🛡️ ONUR CAN PRO BYPASS ACTIVE ✅";
            l.textColor = [UIColor cyanColor];
            l.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
            l.textAlignment = NSTextAlignmentCenter;
            l.font = [UIFont boldSystemFontOfSize:11];
            l.tag = 1907;
            [win addSubview:l];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            start_ui_loop();
        });
    });
}

__attribute__((constructor))
static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        start_ui_loop();
    });
}

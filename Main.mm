#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <unistd.h>
#include <sys/stat.h>
#include <string.h>

// --- INTERPOSE MOTORU (Source: 11) ---
typedef struct interpose_substitution {
    const void* replacement;
    const void* original;
} interpose_substitution_t;

// --- C-STYLE FUNCTION PROTOTYPES (Source: 632) ---
extern "C" {
    int open(const char *path, int oflag, ...);
    char* strstr(const char *haystack, const char *needle);
}

// 1. DOSYA YÖNLENDİRME (ShadowTracker.bin)
int h_open(const char *path, int oflag, mode_t mode) {
    if (path != NULL && strstr(path, "ShadowTrackerExtra")) {
        NSString *binPath = [[NSBundle mainBundle] pathForResource:@"ShadowTracker" ofType:@"bin"];
        if (binPath) return open([binPath UTF8String], oflag, mode);
    }
    return open(path, oflag, mode);
}

// 2. STRSTR FİLTRESİ (Source: 170)
char* h_strstr(const char *s1, const char *s2) {
    if (s2 != NULL) {
        // Dosyada gördüğümüz yasaklı kelimeler
        if (strcmp(s2, "3ae") == 0 || strcmp(s2, "35") == 0 || 
            strcmp(s2, "report") == 0 || strcmp(s2, "shell") == 0 || 
            strcmp(s2, "tdm") == 0 || strcmp(s2, "SecurityCheck") == 0) {
            return NULL; 
        }
    }
    return strstr(s1, s2);
}

// --- INTERPOSE SECTION (Hata Veren Kısım Düzeltildi) ---
__attribute__((used)) static const interpose_substitution_t interpose_list[] 
__attribute__((section("__DATA,__interpose"))) = {
    {(const void*)(unsigned long)&h_open, (const void*)(unsigned long)&open},
    {(const void*)(unsigned long)&h_strstr, (const void*)(unsigned long)&strstr}
};

// 3. UI GÖSTERGESİ (Source: 171)
void show_onur_can_ui() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* s in [UIApplication sharedApplication].connectedScenes) {
                if (s.activationState == UISceneActivationStateForegroundActive) {
                    win = s.windows.firstObject; break;
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
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, win.frame.size.width, 26)];
            label.text = @"🛡️ ONUR CAN PRO BYPASS ACTIVE ✅";
            label.textColor = [UIColor cyanColor];
            label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont boldSystemFontOfSize:10];
            label.tag = 1907;
            [win addSubview:label];
        }
    });
}

__attribute__((constructor))
static void initialize() {
    // AnoSDK Takibi
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        show_onur_can_ui();
    });
}

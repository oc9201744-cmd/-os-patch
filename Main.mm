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

// --- C-STYLE FUNCTION PROTOTYPES ---
extern "C" {
    int open(const char *path, int oflag, ...);
    char* strstr(const char *haystack, const char *needle);
}

// 1. DOSYA YÖNLENDİRME (ShadowTracker.bin)
// Orijinal dosya açıldığında bizim .bin dosyamızı devreye sokar.
int h_open(const char *path, int oflag, mode_t mode) {
    if (path != NULL && strstr(path, "ShadowTrackerExtra")) {
        // ShadowTracker.bin dosyasını Resource içinde ara
        NSString *binPath = [[NSBundle mainBundle] pathForResource:@"ShadowTracker" ofType:@"bin"];
        if (binPath) {
            return open([binPath UTF8String], oflag, mode);
        }
    }
    return open(path, oflag, mode);
}
INTERPOSE_FUNCTION(h_open, open);

// 2. STRSTR BYPASS (Hatasız Sürüm)
// Derleyicinin "const" hatası vermemesi için (char*) cast ekledim.
char* h_strstr(const char *haystack, const char *needle) {
    if (needle != NULL) {
        if (strcmp(needle, "3ae") == 0 || strcmp(needle, "shell") == 0 || 
            strcmp(needle, "tdm") || strcmp(needle, "Anogs") || strcmp(needle, "report") == 0) {
            return NULL; 
        }
    }
    // Orijinal strstr'yi çağır ve tipi zorla (cast)
    return (char*)strstr(haystack, needle);
}
INTERPOSE_FUNCTION(h_strstr, strstr);

// --- UI MOTORU (MODERN SCENE UYUMLU) ---
void display_secure_ui() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *activeWindow = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    activeWindow = scene.windows.firstObject;
                    break;
                }
            }
        }
        if (!activeWindow) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            activeWindow = [UIApplication sharedApplication].keyWindow;
            #pragma clang diagnostic pop
        }

        if (activeWindow && ![activeWindow viewWithTag:1907]) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, activeWindow.frame.size.width, 30)];
            label.text = @"🛡️ ONUR CAN PRO BYPASS ACTIVE ✅";
            label.textColor = [UIColor cyanColor];
            label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont boldSystemFontOfSize:11];
            label.tag = 1907;
            label.layer.zPosition = 99999;
            [activeWindow addSubview:label];
        }
    });
}

__attribute__((constructor))
static void initialize() {
    // 15 saniye sonra lobiye girişte yazıyı bas
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        display_secure_ui();
    });
}

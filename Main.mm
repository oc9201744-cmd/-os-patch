#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <dlfcn.h>

// --- INTERPOSE ALTYAPISI ---
// Bu yapı, dosya imzasını (Hash) bozmadan fonksiyonları yönlendirir.
typedef struct interpose_substitution {
    const void* replacement;
    const void* original;
} interpose_substitution_t;

#define INTERPOSE_FUNCTION(replacement, original) \
    __attribute__((used)) static const interpose_substitution_t interpose_##replacement \
    __attribute__((section("__DATA,__interpose"))) = { (const void*)(unsigned long)&replacement, (const void*)(unsigned long)&original }

// 1. BAN RAPORLARINI MANİPÜLE ET
// bak 4.txt'deki sürüm ve raporlama fonksiyonlarını susturur.
int h_strcmp(const char *s1, const char *s2) {
    if (s1 && s2) {
        // ACE ve ShadowTracker'ın sunucuya gönderdiği "şüpheli" sinyalleri yakala
        if (strstr(s2, "3ae") || strstr(s2, "report") || strstr(s2, "cheat")) {
            return 1; // Eşleşme yok, raporu temizle.
        }
    }
    return strcmp(s1, s2);
}
INTERPOSE_FUNCTION(h_strcmp, strcmp);

// 2. ANTİ-DEBUGGER VE ANALİZ ENGELLEYİCİ
// bak 6.txt içindeki ptrace (0x100 case) kontrollerini pasifize eder.
extern "C" int ptrace(int request, int pid, void* addr, int data);
int h_ptrace(int request, int pid, void* addr, int data) {
    return 0; // Analizi engelle, temiz rapor ver.
}
INTERPOSE_FUNCTION(h_ptrace, ptrace);

// 3. GÖRSEL BİLDİRİM (Security Onur Can)
void show_bypass_active() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window && @available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        }
        if (window) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, window.frame.size.width, 25)];
            label.text = @"🛡️ ONUR CAN - STEALTH ACTIVE";
            label.textColor = [UIColor whiteColor];
            label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont boldSystemFontOfSize:10];
            [window addSubview:label];
        }
    });
}

// BAŞLATICI
__attribute__((constructor))
static void init() {
    // 15 saniye gecikme: Oyun motorunun (ShadowTrackerExtra) oturmasını bekler.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        show_bypass_active();
    });
}

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include <unistd.h>

// --- GÜVENLİ HOOK MEKANİZMASI ---
// Linker hatası almamak için fonksiyonları dlsym ile havada yakalıyoruz.

// 1. BAN FLAG FİLTRESİ (strcmp)
// Bu sistem kütüphanesi olduğu için Interpose burada çalışır.
typedef struct interpose_substitution {
    const void* replacement;
    const void* original;
} interpose_substitution_t;

#define INTERPOSE_FUNCTION(replacement, original) \
    __attribute__((used)) static const interpose_substitution_t interpose_##replacement \
    __attribute__((section("__DATA,__interpose"))) = { (const void*)(unsigned long)&replacement, (const void*)(unsigned long)&original }

int h_strcmp(const char *s1, const char *s2) {
    if (s1 && s2) {
        if (strstr(s2, "3ae") || strstr(s2, "35") || strstr(s2, "report") || 
            strstr(s2, "shell") || strstr(s2, "tdm") || strstr(s2, "SecurityCheck")) {
            return 1; 
        }
    }
    return strcmp(s1, s2);
}
INTERPOSE_FUNCTION(h_strcmp, strcmp);

// 2. ANOSDK & PTRACE (Dinamik Hook)
// Bunları dlsym ile bağlayarak "Undefined symbols" hatasını bitiriyoruz.
void install_dynamic_hooks() {
    void* handle = RTLD_DEFAULT;
    
    // AnoSDK Get Raporu sustur
    void* getReport = dlsym(handle, "_AnoSDKGetReportData");
    if (getReport) {
        // Buraya gerekirse detaylı hooking (MSHookFunction gibi) eklenebilir
        // Şimdilik strcmp üzerinden rapor isimlerini bozmak en güvenlisi.
        NSLog(@"[Onur Can] AnoSDK Found and Monitored.");
    }
}

// --- YAZI MOTORU (DEĞİŞMEDİ) ---
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
        if (!activeWindow) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            activeWindow = [UIApplication sharedApplication].keyWindow;
            #pragma clang diagnostic pop
        }

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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            force_show_onur_can_text();
        });
    });
}

// --- BAŞLATICI ---
__attribute__((constructor))
static void initialize() {
    install_dynamic_hooks();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        force_show_onur_can_text();
    });
}

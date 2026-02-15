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

// 1. BAN ANALİZİ VE RAPOR FİLTRESİ
int h_strcmp(const char *s1, const char *s2) {
    if (s1 && s2) {
        // ACE/ShadowTracker raporlarını ve ban flaglerini (0x35, 3ae vb.) sustur
        if (strstr(s2, "3ae") || strstr(s2, "35") || strstr(s2, "report") || strstr(s2, "SecurityCheck")) {
            return 1; 
        }
    }
    return strcmp(s1, s2);
}
INTERPOSE_FUNCTION(h_strcmp, strcmp);

// 2. ANTİ-DEBUGGER SUSTURUCU
extern "C" int ptrace(int request, int pid, void* addr, int data);
int h_ptrace(int request, int pid, void* addr, int data) {
    return 0; 
}
INTERPOSE_FUNCTION(h_ptrace, ptrace);

// --- YENİLENMİŞ UI (ADINI ÇIKARAN KISIM) ---
void force_show_onur_can_text() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *activeWindow = nil;
        
        // iOS 13+ için sahne (scene) kontrolü
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    for (UIWindow *w in scene.windows) {
                        if (w.isKeyWindow) {
                            activeWindow = w;
                            break;
                        }
                    }
                }
            }
        }
        
        // Eski yöntem yedek
        if (!activeWindow) {
            activeWindow = [UIApplication sharedApplication].keyWindow;
        }

        if (activeWindow) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, activeWindow.frame.size.width, 30)];
            label.text = @"🛡️ ONUR CAN BYPASS ACTIVE ✅";
            label.textColor = [UIColor cyanColor];
            label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont boldSystemFontOfSize:13];
            label.layer.zPosition = 9999; // Her şeyin üstünde dursun
            [activeWindow addSubview:label];
            NSLog(@"[Onur Can] Yazı ekrana basıldı.");
        } else {
            NSLog(@"[Onur Can] Pencere bulunamadı, 2 saniye sonra tekrar denenecek...");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                force_show_onur_can_text();
            });
        }
    });
}

// BAŞLATICI
__attribute__((constructor))
static void init() {
    // 20 saniye bekle (ShadowTrackerExtra'nın UI'ı oluşturması için)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        force_show_onur_can_text();
    });
}

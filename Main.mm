#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include <unistd.h>
#include <sys/sysctl.h>

// --- INTERPOSE ALTYAPISI (Ban Yapısı Burası, Dokunulmadı) ---
typedef struct interpose_substitution {
    const void* replacement;
    const void* original;
} interpose_substitution_t;

#define INTERPOSE_FUNCTION(replacement, original) \
    __attribute__((used)) static const interpose_substitution_t interpose_##replacement \
    __attribute__((section("__DATA,__interpose"))) = { (const void*)(unsigned long)&replacement, (const void*)(unsigned long)&original }

int h_strcmp(const char *s1, const char *s2) {
    if (s1 && s2) {
        if (strstr(s2, "3ae") || strstr(s2, "35") || strstr(s2, "report") || strstr(s2, "SecurityCheck")) {
            return 1; 
        }
    }
    return strcmp(s1, s2);
}
INTERPOSE_FUNCTION(h_strcmp, strcmp);

extern "C" int ptrace(int request, int pid, void* addr, int data);
int h_ptrace(int request, int pid, void* addr, int data) { return 0; }
INTERPOSE_FUNCTION(h_ptrace, ptrace);

// --- YAZIYI ZORLA ÇIKARTAN UI MOTORU ---
void force_draw_text() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        // iOS 13+ En aktif pencereyi bulma
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    win = scene.windows.firstObject;
                    break;
                }
            }
        }
        if (!win) win = [UIApplication sharedApplication].keyWindow;

        // Eğer pencere bulunduysa yazıyı bas
        if (win) {
            // Eğer yazı zaten ekrandaysa tekrar ekleme (Çakışma olmasın)
            if ([win viewWithTag:1907]) return;

            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, win.frame.size.width, 30)];
            label.text = @"🛡️ ONUR CAN SECURE ACTIVE ✅";
            label.textColor = [UIColor cyanColor];
            label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont boldSystemFontOfSize:12];
            label.tag = 1907; // Benzersiz ID
            label.layer.zPosition = 99999; // En üst katmana zorla
            [win addSubview:label];
            NSLog(@"[Onur Can] Yazı ekrana çakıldı!");
        } 
        
        // Oyun lobiye girerken pencereleri sıfırlayabilir. 
        // Bu yüzden her 3 saniyede bir kontrol et, yazı yoksa tekrar bas.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            force_draw_text();
        });
    });
}

// BAŞLATICI
__attribute__((constructor))
static void init() {
    // 15. saniyede motoru başlat
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        force_draw_text();
    });
}

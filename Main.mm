#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include <unistd.h>
#include <string.h>

// --- SİSTEM TANIMLAMALARI (Hata Alan Kısım) ---
extern "C" {
    // ptrace'i burada açıkça tanımlıyoruz ki derleyici hata vermesin
    int ptrace(int _request, pid_t _pid, caddr_t _addr, int _data);
}

// --- INTERPOSE ALTYAPISI ---
typedef struct { 
    const void* replacement; 
    const void* original; 
} interpose_t;

// 1. STRNCMP KANCASI (1 Gün Ban Engelleyici)
// Oyun bir dosyayı veya bayrağı kontrol ederken '0' dönerek "Orijinal" onayı veriyoruz.
int h_strncmp(const char *s1, const char *s2, size_t n) {
    if (s1 && s2) {
        // Pubg.txt içindeki kritik tetikleyiciler
        if (strstr(s2, "3ae") || strstr(s2, "report") || strstr(s2, "SecurityCheck") || strstr(s2, "Cheat")) {
            return 0; // "Eşleşme var, her şey yolunda" (Sahte Onay)
        }
    }
    return strncmp(s1, s2, n);
}

// 2. PTRACE KANCASI (Anti-Debug Bypass)
int h_ptrace(int request, pid_t pid, caddr_t addr, int data) {
    // PT_DENY_ATTACH = 31. Oyun kendini debug'dan korumaya çalışırsa "Tamam" diyoruz.
    if (request == 31) return 0;
    return ptrace(request, pid, addr, data);
}

// 3. UI - DURUM PANELİ (Modern & Safe)
void show_v10_label() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject; break;
                }
            }
        }
        if (!window) window = [UIApplication sharedApplication].windows.firstObject;

        if (window && ![window viewWithTag:2026]) {
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, window.frame.size.width, 25)];
            lbl.text = @"🛡️ ONUR CAN V10: ANTI-BAN ACTIVE ✅";
            lbl.textColor = [UIColor greenColor];
            lbl.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.font = [UIFont boldSystemFontOfSize:11];
            lbl.tag = 2026;
            [window addSubview:lbl];
        }
    });
}

// --- INTERPOSE TABLOSU ---
__attribute__((used)) static const interpose_t interpose_list[] 
__attribute__((section("__DATA,__interpose"))) = {
    {(const void*)&h_strncmp, (const void*)&strncmp},
    {(const void*)&h_ptrace, (const void*)&ptrace}
};

__attribute__((constructor))
static void initialize() {
    // 20 saniye sonra lobiye girişte devreye gir
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        show_v10_label();
    });
}

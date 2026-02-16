#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include <unistd.h>

// --- INTERPOSE SİSTEMİ ---
typedef struct { const void* replacement; const void* original; } interpose_t;

// 1. STRNCMP KANCASI (En Önemli Kısım)
// strcmp yerine strncmp ve strstr kombinasyonu daha güvenlidir.
int h_strncmp(const char *s1, const char *s2, size_t n) {
    if (s1 && s2) {
        // Eğer raporlama veya ban flag sorgusu gelirse
        if (strstr(s2, "3ae") || strstr(s2, "report") || strstr(s2, "SecurityCheck") || strstr(s2, "Cheat")) {
            // 0 döndürerek oyunun "Hata yok, her şey orijinal" sanmasını sağlıyoruz.
            return 0; 
        }
    }
    return strncmp(s1, s2, n);
}

// 2. GÜVENLİ PTRACE (Anti-Debug)
typedef int (*ptrace_t)(int, pid_t, caddr_t, int);
int h_ptrace(int request, pid_t pid, caddr_t addr, int data) {
    // PT_DENY_ATTACH (31) isteğini engelle, geri kalana dokunma
    if (request == 31) return 0;
    return ((ptrace_t)dlsym(RTLD_DEFAULT, "ptrace"))(request, pid, addr, data);
}

// 3. MODERN VE CRASH YAPMAYAN YAZI MOTORU
void show_v9_label() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        // iOS 13+ için en güvenli pencere bulma yöntemi
        for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                win = scene.windows.firstObject; break;
            }
        }
        if (!win) win = [UIApplication sharedApplication].windows.firstObject;

        if (win && ![win viewWithTag:2026]) {
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, win.frame.size.width, 25)];
            lbl.text = @"🛡️ ONUR CAN V9: STEALTH GHOST ✅";
            lbl.textColor = [UIColor greenColor];
            lbl.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.font = [UIFont boldSystemFontOfSize:11];
            lbl.tag = 2026;
            [win addSubview:lbl];
        }
    });
}

// --- INTERPOSE LİSTESİ ---
__attribute__((used)) static const interpose_t interpose_list[] 
__attribute__((section("__DATA,__interpose"))) = {
    {(const void*)&h_strncmp, (const void*)&strncmp},
    {(const void*)&h_ptrace, (const void*)&ptrace}
};

__attribute__((constructor))
static void init() {
    // Oyunun başlangıçtaki dosya kontrollerini (integrity) bozmamak için 
    // Yazıyı lobiye girişte basıyoruz.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        show_v9_label();
    });
}

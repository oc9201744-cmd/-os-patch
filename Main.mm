#include <stdio.h>
#include <string.h>
#include <dlfcn.h>
#include <stdint.h>
#include <sys/mman.h>
#include <mach-o/dyld.h>
#include <UIKit/UIKit.h>

// --- Interpose ---
typedef struct interpose_substitution {
    const void* replacement;
    const void* original;
} interpose_substitution_t;

#define INTERPOSE_FUNCTION(replacement, original) \
    __attribute__((used)) static const interpose_substitution_t interpose_##replacement \
    __attribute__((section("__DATA,__interpose"))) = { (const void*)(unsigned long)&replacement, (const void*)(unsigned long)&original }

// --- Sistem Hookları ---
extern "C" int ptrace(int request, int pid, void* addr, int data);
int my_ptrace(int request, int pid, void* addr, int data) { return 0; }
INTERPOSE_FUNCTION(my_ptrace, ptrace);

int my_strcmp(const char *s1, const char *s2) {
    if (s2 != NULL && strstr(s2, "anti_sp2s")) return 0;
    return strcmp(s1, s2);
}
INTERPOSE_FUNCTION(my_strcmp, strcmp);

// --- Garantili Bildirim (Pop-up Alert) ---
void show_alert() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        if (!rootVC && @available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    rootVC = scene.windows.firstObject.rootViewController;
                    break;
                }
            }
        }
        
        if (rootVC) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"[XO] BYPASS" 
                                        message:@"Sistem Hookları Aktif! İyi Oyunlar." 
                                        preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}

// --- Başlatıcı ---
__attribute__((constructor))
static void initialize() {
    // 20 saniye sonra ekrana bir uyarı penceresi basar
    // Eğer bu pencere gelirse dylib %100 çalışıyor demektir.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        show_alert();
    });
}

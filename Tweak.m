#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <mach-o/dyld.h>
#include <dispatch/dispatch.h>
#include <stdint.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif
    int DobbyHook(void *function_address, void *replace_call, void **origin_call);
#ifdef __cplusplus
}
#endif

typedef long long int64_t;

// Orijinal fonksiyon pointer’ları
static int64_t (*orig_sub_F012C)(void *a1);
static int64_t (*orig_sub_11D85C)(int64_t a1, int64_t a2);

#pragma mark - Hook Fonksiyonları

static int64_t hook_sub_F012C(void *a1) {
    // Güvenli stub
    return 0;
}

static int64_t hook_sub_11D85C(int64_t a1, int64_t a2) {
    if (a2 != 0) {
        uint8_t flag = *(uint8_t *)(a2 + 168);
        if (flag == 0x35) {
            return 1;
        }
    }
    return 0;
}

#pragma mark - ASLR Base Hesabı

static uintptr_t get_game_base(void) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "ShadowTrackerExtra")) {
            return (uintptr_t)(0x100000000ULL + _dyld_get_image_vmaddr_slide(i));
        }
    }
    return 0;
}

#pragma mark - UIWindow Güvenli Alma

static UIWindow *getKeyWindowSafe(void) {
    UIApplication *app = UIApplication.sharedApplication;

    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in app.connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive &&
                [scene isKindOfClass:[UIWindowScene class]]) {

                UIWindowScene *ws = (UIWindowScene *)scene;
                for (UIWindow *w in ws.windows) {
                    if (w.isKeyWindow) {
                        return w;
                    }
                }
            }
        }
    }

    // iOS 11–12 fallback
    return app.keyWindow;
}

#pragma mark - Constructor

__attribute__((constructor))
static void onurcan_initializer(void) {
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(45 * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{

        uintptr_t base = get_game_base();
        if (base == 0) {
            NSLog(@"[onurcan] Base adresi bulunamadı");
            return;
        }

        DobbyHook((void *)(base + 0xF012C),
                  (void *)hook_sub_F012C,
                  (void **)&orig_sub_F012C);

        DobbyHook((void *)(base + 0x11D85C),
                  (void *)hook_sub_11D85C,
                  (void **)&orig_sub_11D85C);

        NSLog(@"[onurcan] Hooklar aktif");

        UIWindow *window = getKeyWindowSafe();
        if (!window || !window.rootViewController) return;

        UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Onurcan"
                                            message:@"Modül yüklendi."
                                     preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[UIAlertAction actionWithTitle:@"Tamam"
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];

        [window.rootViewController presentViewController:alert
                                                 animated:YES
                                               completion:nil];
    });
}
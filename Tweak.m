#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <mach-o/dyld.h>
#include <dispatch/dispatch.h>
#include <stdint.h>
#include <string.h>
#include <stdarg.h>

#ifdef __cplusplus
extern "C" {
#endif
int DobbyHook(void *function_address, void *replace_call, void **origin_call);
#ifdef __cplusplus
}
#endif

typedef long long int64_t_ace;

/* Orijinal fonksiyon pointer’ları */
static int64_t_ace (*orig_sub_F012C)(void *a1);
static int64_t_ace (*orig_sub_11D85C)(int64_t_ace a1, int64_t_ace a2, ...);

#pragma mark - Hook Fonksiyonları

/* 1️⃣ Raporlayıcı */
static int64_t_ace hook_sub_F012C(void *a1) {
    return 0;
}

/* 2️⃣ Case 35 filtreli tarama */
static int64_t_ace hook_sub_11D85C(int64_t_ace a1, int64_t_ace a2, ...) {

    if (a2 && *(uint8_t *)(a2 + 168) == 0x35) {
        return 1; // temiz
    }

    /* Varargs güvenli forward */
    va_list args;
    va_start(args, a2);
    int64_t_ace result = orig_sub_11D85C(a1, a2, args);
    va_end(args);

    return result;
}

#pragma mark - ASLR Base

static uintptr_t get_game_base(void) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "ShadowTrackerExtra")) {
            return (uintptr_t)_dyld_get_image_vmaddr_slide(i) + 0x100000000;
        }
    }
    return 0;
}

#pragma mark - Constructor

__attribute__((constructor))
static void onurcan_initializer(void) {

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(45 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{

        uintptr_t base = get_game_base();
        if (!base) {
            NSLog(@"[onurcan] Base bulunamadı");
            return;
        }

        NSLog(@"[onurcan] Base: 0x%lx", base);

        DobbyHook((void *)(base + 0xF012C),
                  (void *)hook_sub_F012C,
                  (void **)&orig_sub_F012C);

        DobbyHook((void *)(base + 0x11D85C),
                  (void *)hook_sub_11D85C,
                  (void **)&orig_sub_11D85C);

        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:@"Onurcan Bypass"
                                                message:@"Bypass başarıyla yüklendi."
                                         preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Tamam"
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil]];

            UIWindow *window = nil;
            for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject;
                    break;
                }
            }

            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        });
    });
}
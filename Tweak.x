#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <mach-o/dyld.h>
#include <dispatch/dispatch.h>
#include <stdarg.h>
#include <stdint.h>
#include <string.h>

// Dobby kütüphanesini dışarıdan tanıtıyoruz
#ifdef __cplusplus
extern "C" {
#endif
    int DobbyHook(void *function_address, void *replace_call, void **origin_call);
#ifdef __cplusplus
}
#endif

// --- Tip Tanımlamaları ---
typedef long long int64_t_ace;
typedef unsigned long long qword_ace;

// --- Orijinal Fonksiyon Saklayıcıları ---
static int64_t_ace (*orig_sub_F012C)(void *a1);
static unsigned char* (*orig_sub_F838C)(int64_t_ace a1, int64_t_ace (**a2)(), unsigned long long a3, qword_ace *a4);
static int64_t_ace (*orig_sub_11D85C)(int64_t_ace a1, int64_t_ace a2, int64_t_ace a3, int64_t_ace a4, ...);

// --- Hook Fonksiyonları (Bypass Mantığı) ---
static int64_t_ace hook_sub_F012C(void *a1) {
    return 0; // Raporlamayı susturur
}

static unsigned char* hook_sub_F838C(int64_t_ace a1, int64_t_ace (**a2)(), unsigned long long a3, qword_ace *a4) {
    return NULL; // Syscall watcher'ı boşa düşürür
}

static int64_t_ace hook_sub_11D85C(int64_t_ace a1, int64_t_ace a2, int64_t_ace a3, int64_t_ace a4, ...) {
    if (a2 != 0 && *(unsigned char *)(a2 + 168) == 0x35) {
        return 1; // Hafıza taramasını temiz raporlar
    }
    va_list args;
    va_start(args, a4);
    int64_t_ace result = orig_sub_11D85C(a1, a2, a3, a4, args);
    va_end(args);
    return result;
}

// --- ASLR Otomatik Hesaplayıcı ---
uintptr_t get_game_base() {
    uintptr_t slide = 0;
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "ShadowTrackerExtra")) {
            slide = _dyld_get_image_vmaddr_slide(i);
            break;
        }
    }
    return (0x100000000 + slide);
}

// --- Tweak Başlatıcı ---
__attribute__((constructor))
static void initializer(void) {
    // 45 saniye gecikme: Lobiye girmeyi bekliyoruz
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(45.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t base = get_game_base();
        
        // Dobby ile kancaları atıyoruz (Non-JB uyumlu)
        DobbyHook((void *)(base + 0xF012C), (void *)hook_sub_F012C, (void **)&orig_sub_F012C);
        DobbyHook((void *)(base + 0xF838C), (void *)hook_sub_F838C, (void **)&orig_sub_F838C);
        DobbyHook((void *)(base + 0x11D85C), (void *)hook_sub_11D85C, (void **)&orig_sub_11D85C);
        
        // Görsel Uyarı
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"GEMINI V13"
                message:@"Non-JB Bypass Aktif!\nBol killer kanka."
                preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Gazla!" style:UIAlertActionStyleDefault handler:nil]];
            [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];
        });
    });
}

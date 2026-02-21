#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include <stdint.h>

// ================= Dobby =================
#ifdef __cplusplus
extern "C" {
#endif
int DobbyHook(void *function_address, void *replace_call, void **origin_call);
#ifdef __cplusplus
}
#endif

// ================= ANOGS =================

// 👉 IDA’dan aldığın ARM64 adres
#define ANOGS_LOG_ADDR 0x12345678   // BUNU DEĞİŞTİR

typedef void (*anogs_log_t)(const char *msg);
static anogs_log_t orig_anogs_log = NULL;

// ================= Hook =================

void hook_anogs_log(const char *msg) {
    if (msg) {
        NSLog(@"[ANOGS][LOG] %s", msg);
    } else {
        NSLog(@"[ANOGS][LOG] (null)");
    }

    // orijinali çağır (DAVRANIŞ DEĞİŞTİRMEYELİM)
    if (orig_anogs_log) {
        orig_anogs_log(msg);
    }
}

// ================= ASLR =================

static uintptr_t get_slide(void) {
    return (uintptr_t)_dyld_get_image_vmaddr_slide(0);
}

// ================= Init =================

__attribute__((constructor))
static void init_bypass(void) {
    NSLog(@"[BypassTweak] Loaded (arm64)");

    uintptr_t slide = get_slide();
    void *target = (void *)(slide + ANOGS_LOG_ADDR);

    if (DobbyHook(target, (void *)hook_anogs_log, (void **)&orig_anogs_log) == 0) {
        NSLog(@"[ANOGS] Hook success @ %p", target);
    } else {
        NSLog(@"[ANOGS] Hook FAILED");
    }
}
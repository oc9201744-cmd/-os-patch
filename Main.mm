#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <string.h>
#import <sys/time.h>
#import <time.h>
#import <sys/mman.h>
#import <libkern/OSCacheControl.h>
#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import <UIKit/UIKit.h>

#pragma mark - Inline Hook Engine (substrate.h gerektirmez)

#if __arm64__ || __aarch64__

typedef struct {
    void *target;
    void *replacement;
    void **original;
} HookEntry;

static int WriteMemory(void *addr, const void *data, size_t size) {
    kern_return_t kr;
    vm_address_t page = (vm_address_t)addr & ~(vm_address_t)(0x4000 - 1);
    vm_size_t page_size = 0x4000;

    mach_port_t task = mach_task_self();
    kr = vm_protect(task, page, page_size, false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (kr != KERN_SUCCESS) {
        kr = vm_protect(task, page, page_size, false, VM_PROT_READ | VM_PROT_WRITE);
        if (kr != KERN_SUCCESS) return -1;
    }

    memcpy(addr, data, size);

    kr = vm_protect(task, page, page_size, false, VM_PROT_READ | VM_PROT_EXECUTE);
    sys_icache_invalidate(addr, size);

    return 0;
}

static void *CreateTrampoline(void *target) {
    void *trampoline = mmap(NULL, 0x4000, PROT_READ | PROT_WRITE | PROT_EXEC,
                            MAP_PRIVATE | MAP_ANONYMOUS | MAP_JIT, -1, 0);
    if (trampoline == MAP_FAILED) return NULL;

    uint32_t origInstructions[4];
    memcpy(origInstructions, target, 16);

    uint8_t *p = (uint8_t *)trampoline;
    memcpy(p, origInstructions, 16);
    p += 16;

    uintptr_t resumeAddr = (uintptr_t)target + 16;

    uint32_t ldr_x16 = 0x58000050;
    uint32_t br_x16 = 0xD61F0200;
    memcpy(p, &ldr_x16, 4); p += 4;
    memcpy(p, &br_x16, 4); p += 4;
    memcpy(p, &resumeAddr, 8);

    sys_icache_invalidate(trampoline, 0x4000);

    return trampoline;
}

static int InlineHook(void *target, void *replacement, void **origOut) {
    if (!target || !replacement) return -1;

    if (origOut) {
        void *trampoline = CreateTrampoline(target);
        if (!trampoline) return -1;
        *origOut = trampoline;
    }

    uint8_t hookCode[16];
    uint32_t ldr_x16 = 0x58000050;
    uint32_t br_x16 = 0xD61F0200;
    uintptr_t addr = (uintptr_t)replacement;

    memcpy(hookCode, &ldr_x16, 4);
    memcpy(hookCode + 4, &br_x16, 4);
    memcpy(hookCode + 8, &addr, 8);

    return WriteMemory(target, hookCode, 16);
}

#define MSHookFunction(target, replacement, original) InlineHook((void*)(target), (void*)(replacement), (void**)(original))

#endif

#pragma mark - UI GÖSTERGESİ (Eklediğim Bölüm)

void show_success_label() {
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
            lbl.text = @"🛡️ ONUR CAN: PRECISION BYPASS ACTIVE ✅";
            lbl.textColor = [UIColor greenColor];
            lbl.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.font = [UIFont boldSystemFontOfSize:11];
            lbl.tag = 2026;
            [window addSubview:lbl];
        }
    });
}

#pragma mark - Base Address Finder

static uintptr_t getBaseAddress(const char *imageName) {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, imageName)) {
            return (uintptr_t)_dyld_get_image_header(i);
        }
    }
    return 0;
}

#pragma mark - AnoSDK Hooks (Senin Orijinal Ofsetlerin)

static void (*orig_AnoSDKDelReportData3)(void *arg);
static void hook_AnoSDKDelReportData3(void *arg) { return; }

static void *(*orig_AnoSDKGetReportData3)(void);
static void *hook_AnoSDKGetReportData3(void) { return NULL; }

static void (*orig_AnoSDKDelReportData4)(void *arg);
static void hook_AnoSDKDelReportData4(void *arg) { return; }

static void *(*orig_AnoSDKGetReportData4)(int arg);
static void *hook_AnoSDKGetReportData4(int arg) { return NULL; }

static void (*orig_sub_4A130)(void);
static void hook_sub_4A130(void) { return; }

static struct tm *(*orig_gmtime)(const time_t *timep);
static struct tm fake_tm;
static struct tm *hook_gmtime(const time_t *timep) {
    struct tm *result = orig_gmtime(timep);
    if (!result) {
        memset(&fake_tm, 0, sizeof(fake_tm));
        return &fake_tm;
    }
    return result;
}

static int (*orig_gettimeofday)(struct timeval *tv, void *tz);
static int hook_gettimeofday(struct timeval *tv, void *tz) { return orig_gettimeofday(tv, tz); }

static int (*orig_clock_gettime)(clockid_t clk_id, struct timespec *tp);
static int hook_clock_gettime(clockid_t clk_id, struct timespec *tp) { return orig_clock_gettime(clk_id, tp); }

static void *(*orig_memcpy)(void *dest, const void *src, size_t n);
static void *hook_memcpy(void *dest, const void *src, size_t n) {
    if (src && n >= 13) {
        const char *s = (const char *)src;
        if (memcmp(s, "cheat_open_id", 13) == 0) return dest;
    }
    return orig_memcpy(dest, src, n);
}

static void (*orig_sub_E6FDC)(void *arg0, void *arg1, void *arg2);
static void hook_sub_E6FDC(void *arg0, void *arg1, void *arg2) { return; }

static void installHooksWithBase(uintptr_t base) {
    MSHookFunction((void *)(base + 0xF117C), (void *)hook_AnoSDKDelReportData3, (void **)&orig_AnoSDKDelReportData3);
    MSHookFunction((void *)(base + 0xF1178), (void *)hook_AnoSDKGetReportData3, (void **)&orig_AnoSDKGetReportData3);
    MSHookFunction((void *)(base + 0xF1184), (void *)hook_AnoSDKDelReportData4, (void **)&orig_AnoSDKDelReportData4);
    MSHookFunction((void *)(base + 0xF1180), (void *)hook_AnoSDKGetReportData4, (void **)&orig_AnoSDKGetReportData4);
    MSHookFunction((void *)(base + 0x4A130), (void *)hook_sub_4A130, (void **)&orig_sub_4A130);
    MSHookFunction((void *)(base + 0xE6FDC), (void *)hook_sub_E6FDC, (void **)&orig_sub_E6FDC);
}

#pragma mark - Constructor

__attribute__((constructor))
static void tweak_init(void) {
    @autoreleasepool {
        const char *targetLib = "anogs";
        uintptr_t base = getBaseAddress(targetLib);

        if (!base) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                uintptr_t b = getBaseAddress(targetLib);
                if (b) {
                    installHooksWithBase(b);
                    show_success_label(); // Yazıyı ekle
                }
            });
            return;
        }

        installHooksWithBase(base);
        
        MSHookFunction((void *)gettimeofday, (void *)hook_gettimeofday, (void **)&orig_gettimeofday);
        MSHookFunction((void *)gmtime, (void *)hook_gmtime, (void **)&orig_gmtime);
        MSHookFunction((void *)clock_gettime, (void *)hook_clock_gettime, (void **)&orig_clock_gettime);
        MSHookFunction((void *)memcpy, (void *)hook_memcpy, (void **)&orig_memcpy);

        // Yazıyı lobi zamanında göster (15 saniye gecikmeli)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            show_success_label();
        });
    }
}

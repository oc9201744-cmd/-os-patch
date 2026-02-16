#import <substrate.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <string.h>
#import <sys/time.h>
#import <time.h>

static uintptr_t getBaseAddress(const char *imageName) {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, imageName)) {
            return (uintptr_t)_dyld_get_image_header(i);
        }
    }
    return 0;
}

#pragma mark - AnoSDKDelReportData3 Hook (0xF117C / 0x2DCC8)

static void (*orig_AnoSDKDelReportData3)(void *arg);
static void hook_AnoSDKDelReportData3(void *arg) {
    return;
}

#pragma mark - AnoSDKGetReportData3 Hook (0xF1178 / 0x2DC90)

static void *(*orig_AnoSDKGetReportData3)(void);
static void *hook_AnoSDKGetReportData3(void) {
    return NULL;
}

#pragma mark - AnoSDKDelReportData4 Hook (0xF1184 / 0x2DD98)

static void (*orig_AnoSDKDelReportData4)(void *arg);
static void hook_AnoSDKDelReportData4(void *arg) {
    return;
}

#pragma mark - AnoSDKGetReportData4 Hook (0xF1180 / 0x2DD5C)

static void *(*orig_AnoSDKGetReportData4)(int arg);
static void *hook_AnoSDKGetReportData4(int arg) {
    return NULL;
}

#pragma mark - cheat_open_id reporter (sub_4A130)

static void (*orig_sub_4A130)(void);
static void hook_sub_4A130(void) {
    return;
}

#pragma mark - gmtime Hook

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

#pragma mark - gettimeofday Hook

static int (*orig_gettimeofday)(struct timeval *tv, void *tz);
static int hook_gettimeofday(struct timeval *tv, void *tz) {
    return orig_gettimeofday(tv, tz);
}

#pragma mark - clock_gettime Hook

static int (*orig_clock_gettime)(clockid_t clk_id, struct timespec *tp);
static int hook_clock_gettime(clockid_t clk_id, struct timespec *tp) {
    return orig_clock_gettime(clk_id, tp);
}

#pragma mark - memcpy Hook

static void *(*orig_memcpy)(void *dest, const void *src, size_t n);
static void *hook_memcpy(void *dest, const void *src, size_t n) {
    if (src && n >= 13) {
        const char *s = (const char *)src;
        if (memcmp(s, "cheat_open_id", 13) == 0) {
            return dest;
        }
    }
    return orig_memcpy(dest, src, n);
}

#pragma mark - sub_E6FDC (gmtime timestamp converter for ban)

static void (*orig_sub_E6FDC)(void *arg0, void *arg1, void *arg2);
static void hook_sub_E6FDC(void *arg0, void *arg1, void *arg2) {
    return;
}

#pragma mark - Constructor

%ctor {
    @autoreleasepool {
        const char *targetLib = "anogs";
        uintptr_t base = 0;

        for (uint32_t i = 0; i < _dyld_image_count(); i++) {
            const char *name = _dyld_get_image_name(i);
            if (name && strstr(name, targetLib)) {
                base = (uintptr_t)_dyld_get_image_header(i);
                break;
            }
        }

        if (!base) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                for (uint32_t i = 0; i < _dyld_image_count(); i++) {
                    const char *name = _dyld_get_image_name(i);
                    if (name && strstr(name, targetLib)) {
                        uintptr_t b = (uintptr_t)_dyld_get_image_header(i);
                        if (b) {
                            MSHookFunction((void *)(b + 0xF117C), (void *)hook_AnoSDKDelReportData3, (void **)&orig_AnoSDKDelReportData3);
                            MSHookFunction((void *)(b + 0xF1178), (void *)hook_AnoSDKGetReportData3, (void **)&orig_AnoSDKGetReportData3);
                            MSHookFunction((void *)(b + 0xF1184), (void *)hook_AnoSDKDelReportData4, (void **)&orig_AnoSDKDelReportData4);
                            MSHookFunction((void *)(b + 0xF1180), (void *)hook_AnoSDKGetReportData4, (void **)&orig_AnoSDKGetReportData4);
                            MSHookFunction((void *)(b + 0x4A130), (void *)hook_sub_4A130, (void **)&orig_sub_4A130);
                            MSHookFunction((void *)(b + 0xE6FDC), (void *)hook_sub_E6FDC, (void **)&orig_sub_E6FDC);
                        }
                        break;
                    }
                }
            });
            return;
        }

        MSHookFunction((void *)(base + 0xF117C), (void *)hook_AnoSDKDelReportData3, (void **)&orig_AnoSDKDelReportData3);

        MSHookFunction((void *)(base + 0xF1178), (void *)hook_AnoSDKGetReportData3, (void **)&orig_AnoSDKGetReportData3);

        MSHookFunction((void *)(base + 0xF1184), (void *)hook_AnoSDKDelReportData4, (void **)&orig_AnoSDKDelReportData4);

        MSHookFunction((void *)(base + 0xF1180), (void *)hook_AnoSDKGetReportData4, (void **)&orig_AnoSDKGetReportData4);

        MSHookFunction((void *)(base + 0x4A130), (void *)hook_sub_4A130, (void **)&orig_sub_4A130);

        MSHookFunction((void *)(base + 0xE6FDC), (void *)hook_sub_E6FDC, (void **)&orig_sub_E6FDC);

        MSHookFunction((void *)gettimeofday, (void *)hook_gettimeofday, (void **)&orig_gettimeofday);

        MSHookFunction((void *)gmtime, (void *)hook_gmtime, (void **)&orig_gmtime);

        MSHookFunction((void *)clock_gettime, (void *)hook_clock_gettime, (void **)&orig_clock_gettime);

        MSHookFunction((void *)memcpy, (void *)hook_memcpy, (void **)&orig_memcpy);
    }
}

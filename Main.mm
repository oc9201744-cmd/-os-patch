#import <substrate.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#include <pthread.h>
#include <unistd.h>

// --- POINTERLAR VE HOOKLAR (Attığın kodun çekirdeği) ---
static void (*orig_AnoSDKDelReportData3)(void *arg);
static void hook_AnoSDKDelReportData3(void *arg) { return; }

static void *(*orig_AnoSDKGetReportData3)(void);
static void *hook_AnoSDKGetReportData3(void) { return NULL; }

static void (*orig_sub_4A130)(void);
static void hook_sub_4A130(void) { return; }

static void *(*orig_memcpy)(void *dest, const void *src, size_t n);
static void *hook_memcpy(void *dest, const void *src, size_t n) {
    if (src && n >= 13) {
        if (memcmp(src, "cheat_open_id", 13) == 0) return dest;
    }
    return orig_memcpy(dest, src, n);
}

// --- GECİKMELİ HOOK MOTORU ---
void *perform_delayed_hooks(void *arg) {
    // KANKA BURASI ÖNEMLİ: Oyunun tüm korumaları geçmesi için 25 saniye uyuyoruz.
    // Kod hafızada ama henüz kancalar atılmadı.
    sleep(25);

    const char *targetLib = "anogs";
    uintptr_t base = 0;

    // anogs kütüphanesini bul
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, targetLib)) {
            base = (uintptr_t)_dyld_get_image_header(i);
            break;
        }
    }

    if (base) {
        // Lobi aşamasında kancaları çakıyoruz
        MSHookFunction((void *)(base + 0xF117C), (void *)hook_AnoSDKDelReportData3, (void **)&orig_AnoSDKDelReportData3);
        MSHookFunction((void *)(base + 0xF1178), (void *)hook_AnoSDKGetReportData3, (void **)&orig_AnoSDKGetReportData3);
        MSHookFunction((void *)(base + 0x4A130), (void *)hook_sub_4A130, (void **)&orig_sub_4A130);
        MSHookFunction((void *)memcpy, (void *)hook_memcpy, (void **)&orig_memcpy);
        
        printf("[Onur Can] Professional Hooks Deployed at Lobby.\n");
    }
    return NULL;
}

// --- UI DURUM PANELİ ---
void show_v14_label() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        if (win) {
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, win.frame.size.width, 25)];
            lbl.text = @"🛡️ ONUR CAN V14: PRO DELAY ACTIVE ✅";
            lbl.textColor = [UIColor cyanColor];
            lbl.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.font = [UIFont boldSystemFontOfSize:11];
            [win addSubview:lbl];
        }
    });
}

// --- CONSTRUCTOR (HAFIZAYA GİRİŞ ANI) ---
%ctor {
    @autoreleasepool {
        // Oyun açılır açılmaz arka planda bir thread (yol) açıyoruz
        // Bu sayede oyunun ana akışı donmaz ve açılış kontrollerine takılmaz.
        pthread_t t;
        pthread_create(&t, NULL, perform_delayed_hooks, NULL);

        // Yazıyı lobi vaktinde göster
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            show_v14_label();
        });
    }
}

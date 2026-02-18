#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <UIKit/UIKit.h>

// --- DOBBY ---
extern "C" {
    int DobbyHook(void *address, void *replace_call, void **origin_call);
}

// --- UI BİLDİRİM ---
void baybars_alert(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in (NSArray<UIWindowScene*>*)[UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        }
        if (!window) window = [UIApplication sharedApplication].windows.firstObject;
        if (window && window.rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Baybars v11" message:msg preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Gazla!" style:UIAlertActionStyleDefault handler:nil]];
            UIViewController *top = window.rootViewController;
            while (top.presentedViewController) top = top.presentedViewController;
            [top presentViewController:alert animated:YES completion:nil];
        }
    });
}

// --- ANALİZDEN GELEN TÜM OFSETLER (OSUB HOSUB) ---
#define OFS_ROOT_ALERT     0x63D4
#define OFS_HASH2          0x30028
#define OFS_HB_CHECK       0x447B0
#define OFS_CHEAT_DETECT   0x4A130
#define OFS_SC_PROTECT     0x7B2A8
#define OFS_SCREENSHOT     0x7BD90
#define OFS_TCJ_PROTECT    0x815C4
#define OFS_SPEED_CTL      0x94630
#define OFS_ANTI_DATA      0x1007FC
#define OFS_ABORT_DECISION 0xF0CBC

// --- BYPASS HANDLERS ---
void* fake_null(void* a) { return NULL; }
void  fake_void() { return; }
int   fake_zero() { return 0; }
int   fake_sc(void* a, void* b, int c, void* d) { return 0; }
int   fake_tc(void* a, void* b, void* c, void* d, void* e, void* f) { return 0; }

// --- ANA MOTOR (SIRALI YAMA) ---
void apply_full_bypass(uintptr_t base) {
    // 15 saniye sonra başla (Modülün içindeki threadlerin oturması için)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        if (base == 0) return;

        // Her yamadan sonra kısa bir es vererek Integrity Check'i (Bütünlük Kontrolü) bypass ediyoruz
        
        // 1. Root & Jailbreak
        DobbyHook((void *)(base + OFS_ROOT_ALERT), (void *)fake_null, NULL);
        [NSThread sleepForTimeInterval:0.5];

        // 2. Heartbeat & Hile Tespiti
        DobbyHook((void *)(base + OFS_HB_CHECK), (void *)fake_void, NULL);
        DobbyHook((void *)(base + OFS_CHEAT_DETECT), (void *)fake_void, NULL);
        [NSThread sleepForTimeInterval:0.5];

        // 3. Integrity & Hash
        DobbyHook((void *)(base + OFS_SC_PROTECT), (void *)fake_sc, NULL);
        DobbyHook((void *)(base + OFS_HASH2), (void *)fake_zero, NULL);
        [NSThread sleepForTimeInterval:0.5];

        // 4. Diğer Koruma Noktaları
        DobbyHook((void *)(base + OFS_TCJ_PROTECT), (void *)fake_tc, NULL);
        DobbyHook((void *)(base + OFS_SPEED_CTL), (void *)fake_void, NULL);
        DobbyHook((void *)(base + OFS_SCREENSHOT), (void *)fake_void, NULL);
        DobbyHook((void *)(base + OFS_ANTI_DATA), (void *)fake_void, NULL);
        DobbyHook((void *)(base + OFS_ABORT_DECISION), (void *)fake_zero, NULL);

        baybars_alert(@"Osub Hosub Tamamlandı! Tüm Noktalar Hooklandı. ✅");
    });
}

// --- DİNAMİK MODÜL YAKALAYICI ---
void image_added_callback(const struct mach_header *mh, intptr_t vmaddr_slide) {
    Dl_info info;
    if (dladdr(mh, &info)) {
        const char *name = info.dli_fname;
        // Analizindeki modül isimlerine göre arama (Anogs veya libtprt vb.)
        if (name && (strstr(name, "Anogs") || strstr(name, "anogs") || strstr(name, "MRPCS") || strstr(name, "libtprt"))) {
            // Modülün hafızadaki gerçek base adresi vmaddr_slide (ASLR) değeridir.
            apply_full_bypass((uintptr_t)vmaddr_slide);
        }
    }
}

__attribute__((constructor))
static void initialize() {
    // Çalışan kodun kalbi: Modül hafızaya girdiği anı izle
    _dyld_register_func_for_add_image(image_added_callback);
}

#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <UIKit/UIKit.h>

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
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Baybars v12" message:msg preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
            UIViewController *top = window.rootViewController;
            while (top.presentedViewController) top = top.presentedViewController;
            [top presentViewController:alert animated:YES completion:nil];
        }
    });
}

// --- ORIG POINTERS ---
static void* (*orig_root)(void*);
static int   (*orig_sc)(void*, void*, int, void*);
static int   (*orig_tcj)(void*, void*, void*, void*, void*, void*);
static int   (*orig_hash2)(void);

// --- SAFE HOOK HANDLERS (v4 Mantığı: Orijinali Çalıştır, Sonucu Temizle) ---

void* new_root_alert(void* arg) {
    orig_root(arg); // Orijinali çalıştır (Thread bozulmasın)
    return NULL;    // Ama raporu boş dön
}

int new_sc_protect(void* a, void* b, int c, void* d) {
    orig_sc(a, b, c, d); // Bütünlük kontrolü çalışsın
    return 0;            // Ama hata (Abort) kodunu 0 (başarılı) yap
}

int new_tcj_protect(void* x0, void* x1, void* x2, void* x3, void* x4, void* x5) {
    orig_tcj(x0, x1, x2, x3, x4, x5);
    return 0; // Tencent korumasını her zaman "ok" döndür
}

int new_hash2() {
    orig_hash2();
    return 0; // Hash sonucunu temizle
}

// --- ANA MOTOR ---
void apply_crash_safe_bypass(uintptr_t base) {
    // 20 saniye bekleme (v4'teki gibi, en güvenli süre)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        if (base == 0) return;

        // Analizindeki en kritik 4 noktayı v4 mantığıyla hookluyoruz
        // 1. Root Alert
        DobbyHook((void *)(base + 0x63D4), (void *)new_root_alert, (void **)&orig_root);
        [NSThread sleepForTimeInterval:1.5];

        // 2. SC Protect (Crash'in ana sebebi buydu, artık güvenli)
        DobbyHook((void *)(base + 0x7B2A8), (void *)new_sc_protect, (void **)&orig_sc);
        [NSThread sleepForTimeInterval:1.5];

        // 3. Hash2
        DobbyHook((void *)(base + 0x30028), (void *)new_hash2, (void **)&orig_hash2);
        [NSThread sleepForTimeInterval:1.5];

        // 4. TCJ Protect
        DobbyHook((void *)(base + 0x815C4), (void *)new_tcj_protect, (void **)&orig_tcj);

        baybars_alert(@"Baybars v12: Safe Bypass Aktif! 🚀");
    });
}

void image_added_callback(const struct mach_header *mh, intptr_t vmaddr_slide) {
    Dl_info info;
    if (dladdr(mh, &info)) {
        const char *name = info.dli_fname;
        // Analizindeki "Anogs" modülünü v4 gibi yakalıyoruz
        if (name && (strstr(name, "Anogs") || strstr(name, "anogs"))) {
            apply_crash_safe_bypass((uintptr_t)vmaddr_slide);
        }
    }
}

__attribute__((constructor))
static void initialize() {
    _dyld_register_func_for_add_image(image_added_callback);
}

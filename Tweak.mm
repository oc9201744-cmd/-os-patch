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
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Baybars v4" message:msg preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
            UIViewController *top = window.rootViewController;
            while (top.presentedViewController) top = top.presentedViewController;
            [top presentViewController:alert animated:YES completion:nil];
        }
    });
}

// --- HOOKLAR (Analiz: bak 4.txt & bak 6.txt) ---

// Ofset: 0xF838C -> Orijinal akışa izin ver ama sonucu temizle
void *(*orig_sub_F838C)(void *a1, void *a2, unsigned long a3, void *a4);
void *new_sub_F838C(void *a1, void *a2, unsigned long a3, void *a4) {
    // Önce orijinali çalıştır (Oyun veri bekliyorsa hata almasın)
    orig_sub_F838C(a1, a2, a3, a4);
    // Ama sonucu her zaman NULL (temiz) dön
    return NULL; 
}

// Ofset: 0xF012C -> ACE Modülünü orijinal haliyle çalıştır ama loglarını/hatalarını sustur
void (*orig_sub_F012C)(void *a1);
void new_sub_F012C(void *a1) {
    // Hiçbir şey yapmadan dönmek yerine orijinali çağırıp ACE'nin uyanmasını engelleyebiliriz
    // Veya tamamen boş bırakabiliriz. Şimdilik boş bırakıyoruz (ACE'yi durdurmak için).
    return;
}

// --- ANA MOTOR (SIRALI YAMA) ---
void apply_safe_bypass(uintptr_t base) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        if (base == 0) return;

        // Bütünlük kontrolünü (Integrity) şaşırtmak için yamaları 2 saniye arayla yapıyoruz
        
        // 1. Hook
        DobbyHook((void *)(base + 0xF838C), (void *)new_sub_F838C, (void **)&orig_sub_F838C);
        
        [NSThread sleepForTimeInterval:2.0];

        // 2. Hook
        DobbyHook((void *)(base + 0xF012C), (void *)new_sub_F012C, (void **)&orig_sub_F012C);

        baybars_alert(@"Bypass v4: Sıralı Hooklar Tamam! ✅");
    });
}

void image_added_callback(const struct mach_header *mh, intptr_t vmaddr_slide) {
    Dl_info info;
    if (dladdr(mh, &info)) {
        const char *name = info.dli_fname;
        if (name && (strstr(name, "Anogs") || strstr(name, "anogs"))) {
            apply_safe_bypass((uintptr_t)vmaddr_slide);
        }
    }
}

__attribute__((constructor))
static void initialize() {
    _dyld_register_func_for_add_image(image_added_callback);
}

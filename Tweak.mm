#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <UIKit/UIKit.h>

extern "C" {
    int DobbyHook(void *address, void *replace_call, void **origin_call);
    int DobbyCodePatch(void *address, uint8_t *buffer, uint32_t buffer_size);
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
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Baybars Stabil" 
                                                                           message:msg 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
            UIViewController *top = window.rootViewController;
            while (top.presentedViewController) top = top.presentedViewController;
            [top presentViewController:alert animated:YES completion:nil];
        }
    });
}

// --- KRİTİK HOOKLAR ---

// 1. Sistem Dağıtıcısı (0xF838C)
// BUNA DİKKAT: Bunu NULL yaparsak oyun çöker. O yüzden "Passthrough" yapıyoruz.
void *(*orig_sub_F838C)(void *a1, void *a2, unsigned long a3, void *a4);
void *new_sub_F838C(void *a1, void *a2, unsigned long a3, void *a4) {
    // Orijinal fonksiyonu çağırıp sonucunu dönüyoruz.
    // Böylece oyunun bellek yönetimi (mmap) ve zamanlayıcıları (sleep) bozulmuyor.
    return orig_sub_F838C(a1, a2, a3, a4);
}

// 2. ACE Modül Başlatıcı (0xF012C)
// İŞTE BAN BURADA: Bu fonksiyon "XCLOUD_VERSION..." stringlerini ve PID'yi sunucuya yollar.
// Bunu tamamen engelliyoruz.
long long (*orig_sub_F012C)(void *a1);
long long new_sub_F012C(void *a1) {
    // Orijinal fonksiyonu ÇAĞIRMIYORUZ.
    // ACE'nin başlamasını engelliyoruz.
    // Sahte bir "Başarılı" kodu (0) dönüyoruz.
    return 0; 
}

// --- UYGULAMA MOTORU ---
void apply_stable_bypass(uintptr_t base) {
    // Oyunun bellek haritasının oturması için 15 saniye idealdir.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        if (base == 0) return;

        // 1. Hook: Dağıtıcıyı "İzleme Moduna" al (Crash'i engeller)
        DobbyHook((void *)(base + 0xF838C), (void *)new_sub_F838C, (void **)&orig_sub_F838C);
        
        // 2. Hook: İspiyoncu Modülü SUSTUR (Ban'ı engeller)
        DobbyHook((void *)(base + 0xF012C), (void *)new_sub_F012C, (void **)&orig_sub_F012C);

        // 3. Patch: Bütünlük Kontrolünü Geç (NOP)
        uint32_t nop = 0xD503201F;
        DobbyCodePatch((void *)(base + 0xD3844), (uint8_t *)&nop, 4);

        baybars_alert(@"Crash Fixlendi + Ban Koruması Aktif! ✅");
    });
}

void image_added_callback(const struct mach_header *mh, intptr_t vmaddr_slide) {
    Dl_info info;
    if (dladdr(mh, &info)) {
        const char *name = info.dli_fname;
        if (name && (strstr(name, "Anogs") || strstr(name, "anogs"))) {
            apply_stable_bypass((uintptr_t)vmaddr_slide);
        }
    }
}

__attribute__((constructor))
static void initialize() {
    _dyld_register_func_for_add_image(image_added_callback);
}

#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <UIKit/UIKit.h>

extern "C" {
    int DobbyHook(void *address, void *replace_call, void **origin_call);
    int DobbyCodePatch(void *address, uint8_t *buffer, uint32_t buffer_size);
}

// --- UI BİLDİRİM ---
void baybars_alert(NSString *title, NSString *msg) {
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
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
            UIViewController *top = window.rootViewController;
            while (top.presentedViewController) top = top.presentedViewController;
            [top presentViewController:alert animated:YES completion:nil];
        }
    });
}

// --- HOOKLAR (Senin Analizlerin: bak 4.txt & bak 6.txt) ---
void *(*orig_sub_F838C)(void *a1, void *a2, unsigned long a3, void *a4);
void *new_sub_F838C(void *a1, void *a2, unsigned long a3, void *a4) { 
    return NULL; 
}

void (*orig_sub_F012C)(void *a1);
void new_sub_F012C(void *a1) { 
    return; 
}

// --- ANA BYPASS (KONTROLLÜ) ---
void apply_baybars_bypass(uintptr_t base) {
    // 30 saniye boyunca bekle, bu sırada oyun açılış kontrollerini yapsın.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        // SON KONTROL: Adres hala geçerli mi?
        if (base == 0) {
            baybars_alert(@"HATA", @"Anogs adresi bulunamadı, bypass iptal!");
            return;
        }

        // Hookları Dobby ile çakıyoruz
        DobbyHook((void *)(base + 0xF838C), (void *)new_sub_F838C, (void **)&orig_sub_F838C);
        DobbyHook((void *)(base + 0xF012C), (void *)new_sub_F012C, (void **)&orig_sub_F012C);

        uint32_t nop = 0xD503201F;
        DobbyCodePatch((void *)(base + 0xD3844), (uint8_t *)&nop, 4);

        baybars_alert(@"BAŞARILI", @"Anogs bulundu ve 30 sn sonra hooklandı! ✅");
    });
}

// --- DİNAMİK YAKALAYICI ---
void image_added_callback(const struct mach_header *mh, intptr_t vmaddr_slide) {
    Dl_info info;
    if (dladdr(mh, &info)) {
        const char *name = info.dli_fname;
        // Kütüphane adı kontrolü
        if (name && (strstr(name, "Anogs") || strstr(name, "anogs"))) {
            // Bulundu! Şimdi gecikmeli işleme gönder.
            apply_baybars_bypass((uintptr_t)vmaddr_slide);
        }
    }
}

__attribute__((constructor))
static void initialize() {
    // Kütüphane yüklendiğinde haber vermesi için sisteme kaydoluyoruz
    _dyld_register_func_for_add_image(image_added_callback);
}

#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <UIKit/UIKit.h>

extern "C" {
    int DobbyHook(void *address, void *replace_call, void **origin_call);
    int DobbyCodePatch(void *address, uint8_t *buffer, uint32_t buffer_size);
}

// --- UI MOTORU ---
void show_baybars_ui(NSString *msg) {
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
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Baybars Bypass" message:msg preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
            UIViewController *top = window.rootViewController;
            while (top.presentedViewController) top = top.presentedViewController;
            [top presentViewController:alert animated:YES completion:nil];
        }
    });
}

// --- HOOKLAR (bak 4.txt & bak 6.txt) ---
void *(*orig_sub_F838C)(void *a1, void *a2, unsigned long a3, void *a4);
void *new_sub_F838C(void *a1, void *a2, unsigned long a3, void *a4) {
    return NULL; 
}

void (*orig_sub_F012C)(void *a1);
void new_sub_F012C(void *a1) {
    return;
}

// --- GECİKMELİ UYGULAMA ---
void apply_bypass_delayed(uintptr_t aslr_slide) {
    // Oyunun ve Anogs'un tam yüklenmesi için 8 saniye bekle
    // Bu süre çökmeyi engellemek için kritiktir.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        // Hook 1: Dispatcher
        DobbyHook((void *)(aslr_slide + 0xF838C), (void *)new_sub_F838C, (void **)&orig_sub_F838C);
        
        // Hook 2: ACE Module
        DobbyHook((void *)(aslr_slide + 0xF012C), (void *)new_sub_F012C, (void **)&orig_sub_F012C);

        // Patch: NOP (0xD3844)
        uint32_t nop = 0xD503201F;
        DobbyCodePatch((void *)(aslr_slide + 0xD3844), (uint8_t *)&nop, 4);

        show_baybars_ui(@"Güvenli Gecikme Tamamlandı\nBypass Aktif! ✅");
    });
}

// --- ASLR TAKİPÇİSİ ---
void image_added_callback(const struct mach_header *mh, intptr_t vmaddr_slide) {
    Dl_info info;
    if (dladdr(mh, &info)) {
        const char *image_name = info.dli_fname;
        if (image_name && (strstr(image_name, "Anogs") || strstr(image_name, "anogs"))) {
            // ASLR'ı yakaladık ama hemen yama yapmıyoruz, gecikmeliye gönderiyoruz
            apply_bypass_delayed((uintptr_t)vmaddr_slide);
        }
    }
}

__attribute__((constructor))
static void initialize() {
    _dyld_register_func_for_add_image(image_added_callback);
}

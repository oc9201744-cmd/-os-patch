#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <UIKit/UIKit.h>

// Dobby fonksiyonlarını kütüphaneden (libdobby.a) bağlamak için manuel tanım
extern "C" {
    int DobbyHook(void *address, void *replace_call, void **origin_call);
    int DobbyCodePatch(void *address, uint8_t *buffer, uint32_t buffer_size);
}

// --- GÖRSEL ÇİZİM (UI) MOTORU ---
void show_baybars_ui(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        
        // Modern iOS (13+) için sahne üzerinden pencere bulma
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in (NSArray<UIWindowScene*>*)[UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        }
        
        // Eğer scene bulunamazsa veya eski iOS ise
        if (!window) window = [UIApplication sharedApplication].windows.firstObject;

        if (window && window.rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Baybars Bypass" 
                                                                           message:msg 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
            
            // Oyunun UI katmanlarının altında kalmamak için en üstteki Controller'ı bul
            UIViewController *topController = window.rootViewController;
            while (topController.presentedViewController) {
                topController = topController.presentedViewController;
            }
            [topController presentViewController:alert animated:YES completion:nil];
        }
    });
}

// --- HOOKLAR (Analiz: bak 4.txt & bak 6.txt) ---

// 0xF838C -> Sistem Çağrısı Dağıtıcısı
void *(*orig_sub_F838C)(void *a1, void *a2, unsigned long a3, void *a4);
void *new_sub_F838C(void *a1, void *a2, unsigned long a3, void *a4) {
    return NULL; // Taramaları blokla
}

// 0xF012C -> ACE Modül Başlatıcı
void (*orig_sub_F012C)(void *a1);
void new_sub_F012C(void *a1) {
    return; // ACE 7.7.31 susturuldu
}

// --- OTOMATİK ASLR UYGULAYICI ---
void apply_bypass(uintptr_t aslr_slide) {
    static bool completed = false;
    if (completed) return;

    // Gerçek Adres = ASLR Slide + Ofset
    // Hook 1: Dispatcher
    DobbyHook((void *)(aslr_slide + 0xF838C), (void *)new_sub_F838C, (void **)&orig_sub_F838C);
    
    // Hook 2: ACE Module
    DobbyHook((void *)(aslr_slide + 0xF012C), (void *)new_sub_F012C, (void **)&orig_sub_F012C);

    // Patch: NOP (0xD3844)
    uint32_t nop = 0xD503201F;
    DobbyCodePatch((void *)(aslr_slide + 0xD3844), (uint8_t *)&nop, 4);

    completed = true;
    show_baybars_ui(@"ASLR Otomatik Hesaplandı\nBypass Aktif! ✅");
}

// --- DİNAMİK TAKİPÇİ (Callback) ---
void image_added_callback(const struct mach_header *mh, intptr_t vmaddr_slide) {
    const char *image_name = _dyld_get_image_name_containing_address(mh);
    
    // Dosya yolu içinde Anogs framework'ü geçtiği an ASLR slide'ı yakala
    if (image_name && (strstr(image_name, "Anogs") || strstr(image_name, "anogs"))) {
        apply_bypass((uintptr_t)vmaddr_slide);
    }
}

__attribute__((constructor))
static void initialize() {
    // 1. Durum: Framework zaten yüklüyse (Çok hızlı yüklenmişse)
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && (strstr(name, "Anogs") || strstr(name, "anogs"))) {
            apply_bypass(_dyld_get_image_vmaddr_slide(i));
            return;
        }
    }

    // 2. Durum: Framework yüklendiği an tetiklenmesi için kaydol (Garanti Yol)
    _dyld_register_func_for_add_image(image_added_callback);
}

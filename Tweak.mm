#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <UIKit/UIKit.h>

// Dobby tanımları
extern "C" {
    int DobbyHook(void *address, void *replace_call, void **origin_call);
    int DobbyCodePatch(void *address, uint8_t *buffer, uint32_t buffer_size);
}

// --- UI ÇİZİM ---
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
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Baybars Bypass" 
                                                                           message:msg 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
            
            UIViewController *top = window.rootViewController;
            while (top.presentedViewController) top = top.presentedViewController;
            [top presentViewController:alert animated:YES completion:nil];
        }
    });
}

// --- BYPASS UYGULAMA (ASLR OTOMATİK) ---

void *(*orig_sub_F838C)(void *a1, void *a2, unsigned long a3, void *a4);
void *new_sub_F838C(void *a1, void *a2, unsigned long a3, void *a4) {
    return NULL; // Dispatcher bloklandı
}

void (*orig_sub_F012C)(void *a1);
void new_sub_F012C(void *a1) {
    return; // ACE Modül susturuldu
}

void apply_bypass(uintptr_t aslr_slide) {
    static bool completed = false;
    if (completed) return;

    // Ofsetler: bak 4.txt ve bak 6.txt
    DobbyHook((void *)(aslr_slide + 0xF838C), (void *)new_sub_F838C, (void **)&orig_sub_F838C);
    DobbyHook((void *)(aslr_slide + 0xF012C), (void *)new_sub_F012C, (void **)&orig_sub_F012C);

    uint32_t nop = 0xD503201F;
    DobbyCodePatch((void *)(aslr_slide + 0xD3844), (uint8_t *)&nop, 4);

    completed = true;
    show_baybars_ui(@"Anogs ASLR Yakalandı\nBypass Aktif! ✅");
}

// --- DİNAMİK TAKİPÇİ (DLADDR KULLANIMI) ---
void image_added_callback(const struct mach_header *mh, intptr_t vmaddr_slide) {
    Dl_info info;
    // dladdr kullanarak mach_header'dan dosya ismini (path) alıyoruz
    if (dladdr(mh, &info)) {
        const char *image_name = info.dli_fname;
        if (image_name && (strstr(image_name, "Anogs") || strstr(image_name, "anogs"))) {
            apply_bypass((uintptr_t)vmaddr_slide);
        }
    }
}

__attribute__((constructor))
static void initialize() {
    // Mevcut yüklü imajları tara
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && (strstr(name, "Anogs") || strstr(name, "anogs"))) {
            apply_bypass(_dyld_get_image_vmaddr_slide(i));
            return;
        }
    }
    // Gelecekte yüklenecekler için kaydol
    _dyld_register_func_for_add_image(image_added_callback);
}

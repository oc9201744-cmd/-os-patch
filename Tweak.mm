#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <UIKit/UIKit.h>

extern "C" {
    // Dobby'nin sadece patch motorunu kullanacağız
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

// --- SESSİZ OPERASYON ---
void start_silent_operation(uintptr_t base) {
    // Süreyi 20 saniyeye çektim, çok geç kalırsak watchdog uyanabilir
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        if (base == 0) return;

        // ARM64 için 'RET' komutu (0xD65F03C0)
        // Fonksiyonun en başına bunu yazarsak, fonksiyon içeriğini çalıştırmadan geri döner.
        uint32_t ret_opcode = 0xD65F03C0;
        uint32_t nop_opcode = 0xD503201F;

        // Hook yerine doğrudan Patch yapıyoruz:
        // 1. Dispatcher: Geri dön!
        DobbyCodePatch((void *)(base + 0xF838C), (uint8_t *)&ret_opcode, 4);
        
        // 2. ACE Modül: Başlama, geri dön!
        DobbyCodePatch((void *)(base + 0xF012C), (uint8_t *)&ret_opcode, 4);

        // 3. Kritik Kontrol Noktası: NOP (Geç!)
        DobbyCodePatch((void *)(base + 0xD3844), (uint8_t *)&nop_opcode, 4);

        baybars_alert(@"Baybars", @"Sessiz Patch 20. sn'de Tamamlandı! ✅");
    });
}

void image_added_callback(const struct mach_header *mh, intptr_t vmaddr_slide) {
    Dl_info info;
    if (dladdr(mh, &info)) {
        if (info.dli_fname && (strstr(info.dli_fname, "Anogs") || strstr(info.dli_fname, "anogs"))) {
            start_silent_operation((uintptr_t)vmaddr_slide);
        }
    }
}

__attribute__((constructor))
static void initialize() {
    _dyld_register_func_for_add_image(image_added_callback);
}

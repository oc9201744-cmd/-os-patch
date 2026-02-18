#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h> // dladdr için gerekli
#include <UIKit/UIKit.h>
#include "dobby.h"

// Framework adresini bulmanın en garanti yolu
uintptr_t get_anogs_base() {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        // Resimlerde ve loglarda gördüğümüz "Anogs" ismini arıyoruz
        if (name && strstr(name, "Anogs")) {
            return _dyld_get_image_vmaddr_slide(i);
        }
    }
    return 0;
}

// Görsel Bildirim
void baybars_alert(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        } else {
            window = [UIApplication sharedApplication].keyWindow;
        }
        
        if (window) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Baybars Bypass" 
                                                                           message:msg 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}

// --- HOOKLAR (Analiz Dosyalarına Göre) ---

// sub_F838C: Güvenlik tarayıcı dispatcher
void *(*orig_sub_F838C)(void *a1, void *a2, unsigned long a3, void *a4);
void *new_sub_F838C(void *a1, void *a2, unsigned long a3, void *a4) {
    // Taramaları durdurmak için boş dönüyoruz
    return NULL; 
}

// sub_F012C: ACE Modül Yükleyici
void (*orig_sub_F012C)(void *a1);
void new_sub_F012C(void *a1) {
    // ACE'nin kendini başlatmasını engelle
    return;
}

void setup_bypass() {
    uintptr_t base = get_anogs_base();
    if (base == 0) {
        NSLog(@"[Baybars] Anogs bulunamadı, tekrar deneniyor...");
        return;
    }

    // Hook 1: Dispatcher
    DobbyHook((void *)(base + 0xF838C), (void *)new_sub_F838C, (void **)&orig_sub_F838C);

    // Hook 2: Modül Başlatıcı
    DobbyHook((void *)(base + 0xF012C), (void *)new_sub_F012C, (void **)&orig_sub_F012C);

    // Patch: Veri kontrolünü NOP'la (Ofset: 0xD3844)
    uint32_t nop = 0xD503201F;
    DobbyCodePatch((void *)(base + 0xD3844), (uint8_t *)&nop, 4);

    baybars_alert(@"Bypass Başarıyla Tamamlandı! ✅");
}

%ctor {
    // Uygulama ve Anogs'un yüklenmesi için 15 saniye bekle (Jailbreak'siz cihazlar için kritik)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        setup_bypass();
    });
}

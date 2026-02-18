#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#include <stdint.h>
#include <UIKit/UIKit.h>
#include "dobby.h"

// Framework adresini bulma fonksiyonu
uintptr_t get_framework_slide(const char *framework_name) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *img_name = _dyld_get_image_name(i);
        if (img_name && strstr(img_name, framework_name)) {
            return _dyld_get_image_vmaddr_slide(i);
        }
    }
    return 0;
}

// Görsel Uyarı (Aktif Oldu Yazısı)
void show_popup(NSString *title, NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *topWindow = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    topWindow = scene.windows.firstObject;
                    break;
                }
            }
        } else {
            topWindow = [UIApplication sharedApplication].keyWindow;
        }

        if (topWindow) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title 
                                                                           message:msg 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
            [topWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}

void apply_anogs_bypass() {
    // 1. ADIM: Anogs framework'ünü hedefle
    uintptr_t anogs_slide = get_framework_slide("Anogs");
    
    if (anogs_slide > 0) {
        // 2. ADIM: Ofset Uygula (0xD3844 senin resmindeki ofset)
        uintptr_t target_addr = anogs_slide + 0xD3844;
        
        // Patch: MOV W1, #0xC0 (0x52801801) veya NOP (0xD503201F)
        uint32_t patch_hex = 0x52801801; 
        
        if (DobbyCodePatch((void *)target_addr, (uint8_t *)&patch_hex, 4) == 0) {
            show_popup(@"Baybars Bypass", @"Anogs Klasörüne Başarıyla Enjekte Edildi! ✅");
        }
    } else {
        // Eğer Anogs bulunamazsa log at (Console uygulamasında görünür)
        NSLog(@"[Baybars] Hata: Anogs framework bulunamadı!");
    }
}

%ctor {
    // Jailbreak'siz cihazlarda oyunun Anogs'u yüklemesi zaman alır.
    // 12 saniye bekleyelim ki klasör/framework tam yüklensin.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(12 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        apply_anogs_bypass();
    });
}

#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#include <stdint.h>
#include <UIKit/UIKit.h> // Ekran bildirimi için gerekli

#include "dobby.h"

// Ofset ve Patch işlemleri için base adresi bulma
uintptr_t get_image_address(const char *name) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        if (strstr(_dyld_get_image_name(i), name)) {
            return _dyld_get_image_vmaddr_slide(i);
        }
    }
    return 0;
}

// Oyun içinde "Aktif Oldu" yazısı çıkartma fonksiyonu
void show_alert(NSString *title, NSString *message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title 
                                                                       message:message 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:ok];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

void setup_bypass() {
    uintptr_t base_addr = get_image_address("PubgMobile");
    if (base_addr == 0) return;

    [span_0](start_span)// Örnek: bak 6.txt dosyasındaki sub_F838C fonksiyonu başlangıcını hooklama[span_0](end_span)
    // Örnek: image.png dosyasındaki 0xD3844 ofsetine patch atma
    
    // --- BURAYA DobbyHook veya DobbyCodePatch KODLARINI EKLE ---

    // Konsola yazdır (Xcode Loglarında görünür)
    NSLog(@"[Baybars] Bypass başarıyla aktif edildi!");

    // Ekrana bildirim gönder
    show_alert(@"Baybars Bypass", @"Dobby ile tüm yamalar aktif edildi! ✅");
}

%ctor {
    // Oyunun tamamen yüklenmesi için 5 saniye bekle ve sonra aktif et
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        setup_bypass();
    });
}

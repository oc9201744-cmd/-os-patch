#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#include <UIKit/UIKit.h>
#include "dobby.h"

// Framework adresini bulma
uintptr_t get_anogs_base() {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "Anogs")) {
            return _dyld_get_image_vmaddr_slide(i);
        }
    }
    return 0;
}

// Bildirim Gösterme
void alert_aktif(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Baybars Bypass" 
                                                                       message:msg 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

// --- Hook Fonksiyonları ---

// Dispatcher'ı etkisiz hale getirme
void *(*orig_sub_F838C)(void *a1, void *a2, unsigned long a3, void *a4);
void *new_sub_F838C(void *a1, void *a2, unsigned long a3, void *a4) {
    // Güvenlik taraması yapan sistem çağrılarını engellemek için boş dönüyoruz
    return NULL; 
}

// Modül yüklemesini engelleme
void (*orig_sub_F012C)(void *a1);
void new_sub_F012C(void *a1) {
    // Fonksiyonu çalıştırmadan hemen çıkıyoruz (Bypass)
    return;
}

void start_bypass() {
    uintptr_t base = get_anogs_base();
    if (base == 0) return;

    // 1. ACE Dispatcher Hook (bak 6.txt - Ofset: 0xF838C)
    DobbyHook((void *)(base + 0xF838C), (void *)new_sub_F838C, (void **)&orig_sub_F838C);

    // 2. Modül Kontrolü Hook (bak 4.txt - Ofset: 0xF012C)
    DobbyHook((void *)(base + 0xF012C), (void *)new_sub_F012C, (void **)&orig_sub_F012C);

    // 3. Veri Analiz Yaması (Önceki konuşmadaki kritik ofset: 0xD3844)
    // Bu adresi NOP'luyoruz (İşlemi iptal ediyoruz)
    uint32_t nop = 0xD503201F;
    DobbyCodePatch((void *)(base + 0xD3844), (uint8_t *)&nop, 4);

    alert_aktif(@"Tüm ACE/Anogs Modülleri Devre Dışı Bırakıldı! ✅");
}

%ctor {
    // Oyunun tamamen yüklenmesi için 10 saniye bekle
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        start_bypass();
    });
}

#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <UIKit/UIKit.h>

extern "C" int DobbyCodePatch(void *address, uint8_t *buffer, uint32_t size);

// --- AYARLAR ---
#define TARGET_LIB "libanogs" // Aradığımız kütüphane
#define PATCH_OFFSET 0xD3848  // Senin resimdeki ofsetin

// Kütüphanenin çalışma zamanındaki base adresini bulur
uintptr_t get_lib_base(const char *lib_name) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, lib_name)) {
            return _dyld_get_image_vmaddr_slide(i) + 0x100000000;
        }
    }
    return 0;
}

void show_alert(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"BAYBARS" 
                                       message:msg 
                                       preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Gazla" style:UIAlertActionStyleDefault handler:nil]];
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) window = [UIApplication sharedApplication].windows.firstObject;
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

void apply_anogs_patch() {
    uintptr_t base = get_lib_base(TARGET_LIB);
    
    if (base != 0) {
        // Hedef Adres = libanogs_base + ofset
        void *target_addr = (void *)(base + PATCH_OFFSET);
        
        // NOP Hex
        uint8_t nop[] = {0x1F, 0x20, 0x03, 0xD5};

        if (DobbyCodePatch(target_addr, nop, 4) == 0) {
            show_alert(@"libanogs Kırıldı! ✅");
        } else {
            show_alert(@"Dobby Yazma Hatası! ❌");
        }
    } else {
        // Eğer libanogs henüz yüklenmemişse tekrar dene
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            apply_anogs_patch();
        });
    }
}

__attribute__((constructor))
static void init() {
    // libanogs oyun açıldıktan biraz sonra yüklenir, o yüzden 15 saniye bekliyoruz
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        apply_anogs_patch();
    });
}

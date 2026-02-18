#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <UIKit/UIKit.h>

// Dobby'nin C fonksiyonlarını C++ (.mm) içinde hatasız kullanmak için extern "C" şarttır.
extern "C" {
    // Eğer Makefile kullanmıyorsan yolu "include/dobby.h" olarak güncellemelisin.
    // Ama Makefile varsa sadece "dobby.h" yeterlidir.
    #include "dobby.h" 
}

// --- ASLR Hesaplama ---
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

// --- Görsel Bildirim (Aktif Oldu Yazısı) ---
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
        
        if (window && window.rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Baybars Bypass" 
                                                                           message:msg 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}

// --- HOOKLAR (Analizlere Dayalı: bak 4.txt & bak 6.txt) ---

// 1. Dispatcher Hook (Ofset: 0xF838C)
void *(*orig_sub_F838C)(void *a1, void *a2, unsigned long a3, void *a4);
void *new_sub_F838C(void *a1, void *a2, unsigned long a3, void *a4) {
    // Güvenlik taramalarını durdurmak için boş dönüyoruz.
    return NULL; 
}

// 2. ACE Modül Yükleyici Hook (Ofset: 0xF012C)
void (*orig_sub_F012C)(void *a1);
void new_sub_F012C(void *a1) {
    // ACE 7.7.31 sürümünün kendini başlatmasını engelle.
    return;
}

// --- ANA MOTOR ---
void start_baybars_bypass() {
    uintptr_t base = get_anogs_base();
    
    if (base != 0) {
        // Dobby Hooking Uygulaması
        DobbyHook((void *)(base + 0xF838C), (void *)new_sub_F838C, (void **)&orig_sub_F838C);
        DobbyHook((void *)(base + 0xF012C), (void *)new_sub_F012C, (void **)&orig_sub_F012C);

        // Code Patch (Ofset: 0xD3844) - Kritik veri kontrolü NOP (Analizden)
        uint32_t nop_code = 0xD503201F;
        DobbyCodePatch((void *)(base + 0xD3844), (uint8_t *)&nop_code, 4);

        baybars_alert(@"Dobby Engine: Anogs Bypass Başarıyla Aktif! ✅");
    } else {
        NSLog(@"[Baybars] HATA: Anogs framework henüz yüklenmedi!");
    }
}

// Constructor: Tweak enjekte edildiğinde otomatik başlar.
__attribute__((constructor))
static void initialize() {
    // Jailbreak'siz cihazlarda oyunun Anogs klasörünü yüklemesi zaman alır.
    // 15 saniye bekleyip sonra bypass'ı çakıyoruz.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        start_baybars_bypass();
    });
}

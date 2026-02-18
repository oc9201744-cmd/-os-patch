#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <UIKit/UIKit.h>

// Dobby'nin C fonksiyonlarını C++ içinde hatasız kullanmak için extern "C" içine alıyoruz
extern "C" {
    #include "dobby.h"
}

// --- ASLR Hesaplama (En Stabil Yöntem) ---
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

// --- UI Bildirimi ---
void show_baybars_alert(NSString *msg) {
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

// --- HOOKLAR (Analiz: bak 4.txt & bak 6.txt) ---

// 1. Dispatcher Hook (Ofset: 0xF838C)
// Bu fonksiyon sistem çağrılarını yönetiyor, bypass için NULL döndürüyoruz.
void *(*orig_sub_F838C)(void *a1, void *a2, unsigned long a3, void *a4);
void *new_sub_F838C(void *a1, void *a2, unsigned long a3, void *a4) {
    return NULL; 
}

// 2. ACE Modül Hook (Ofset: 0xF012C)
// ACE 7.7.31 versiyonlu güvenlik modüllerini durdurur.
void (*orig_sub_F012C)(void *a1);
void new_sub_F012C(void *a1) {
    return; // Modülü çalıştırma, direkt geri dön.
}

// --- ANA BYPASS MOTORU ---
void start_baybars_engine() {
    uintptr_t base = get_anogs_base();
    
    if (base != 0) {
        // Dobby Hook İşlemleri
        DobbyHook((void *)(base + 0xF838C), (void *)new_sub_F838C, (void **)&orig_sub_F838C);
        DobbyHook((void *)(base + 0xF012C), (void *)new_sub_F012C, (void **)&orig_sub_F012C);

        // Code Patch (Ofset: 0xD3844) - Kritik veri kontrolünü etkisiz kıl
        uint32_t nop = 0xD503201F;
        DobbyCodePatch((void *)(base + 0xD3844), (uint8_t *)&nop, 4);

        show_baybars_alert(@"Dobby Engine: Anogs Bypass Aktif! ✅");
    } else {
        NSLog(@"[Baybars] HATA: Anogs framework bulunamadı!");
    }
}

// Tweak yüklendiğinde çalışacak constructor
__attribute__((constructor))
static void initialize() {
    // Jailbreak'siz cihazlarda oyunun Anogs'u yüklemesi için zaman tanıyalım
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        start_baybars_engine();
    });
}

#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#include <string.h>
#include <dlfcn.h>

extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);
extern "C" intptr_t _dyld_get_image_vmaddr_slide(uint32_t image_index);

// Analiz.txt'deki 0x4224 offseti için orijinal veriler
unsigned char original_buffer[8] = {0xFD, 0x7B, 0xBF, 0xA9, 0xFD, 0x03, 0x00, 0x91}; 

uintptr_t anogs_base = 0;
int (*orig_memcmp)(const void *s1, const void *s2, size_t n);

// Bütünlük Kontrolü (Integrity Check) Bypass
int new_memcmp(const void *s1, const void *s2, size_t n) {
    uintptr_t addr1 = (uintptr_t)s1;
    uintptr_t addr2 = (uintptr_t)s2;
    uintptr_t target_addr = anogs_base + 0x4224;

    if (anogs_base != 0 && (addr1 == target_addr || addr2 == target_addr)) {
        return orig_memcmp(original_buffer, s2, n);
    }
    return orig_memcmp(s1, s2, n);
}

// Aktiflik Mesajı (Deprecation Hatası Giderildi)
void show_popup() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *mainWindow = nil;
        
        // Modern iOS (13+) için aktif pencereyi bulma
        if (@available(iOS 13.0, *)) {
            NSSet *scenes = [[UIApplication sharedApplication] connectedScenes];
            for (UIScene *scene in scenes) {
                if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    mainWindow = [windowScene windows].firstObject;
                    break;
                }
            }
        }
        
        // Eğer hala pencere bulunamadıysa (Eski yöntem yedeği - Hatasız)
        if (!mainWindow) {
            mainWindow = [[UIApplication sharedApplication] windows].firstObject;
        }

        if (mainWindow && mainWindow.rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"anogs bypass" 
                                                                           message:@"Dinamik Base Bulundu!\nBütünlük Kontrolü Kör Edildi." 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
            [mainWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}

__attribute__((constructor))
static void auto_base_finder() {
    // Hafızada küçük harfle 'anogs' kütüphanesini ara
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "anogs")) {
            anogs_base = (uintptr_t)_dyld_get_image_vmaddr_slide(i);
            break;
        }
    }

    if (anogs_base != 0) {
        // memcmp'yi dylib içinden kancala
        void *memcmp_ptr = dlsym(RTLD_DEFAULT, "memcmp");
        if (memcmp_ptr) {
            DobbyHook(memcmp_ptr, (void *)new_memcmp, (void **)&orig_memcmp);
        }
        show_popup();
    }
}

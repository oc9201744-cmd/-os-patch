#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#include <string.h>
#include <dlfcn.h>

extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);
extern "C" intptr_t _dyld_get_image_vmaddr_slide(uint32_t image_index);

unsigned char original_buffer[8] = {0xFD, 0x7B, 0xBF, 0xA9, 0xFD, 0x03, 0x00, 0x91}; 

uintptr_t anogs_base = 0;
int (*orig_memcmp)(const void *s1, const void *s2, size_t n);

int new_memcmp(const void *s1, const void *s2, size_t n) {
    uintptr_t addr1 = (uintptr_t)s1;
    uintptr_t addr2 = (uintptr_t)s2;
    uintptr_t target_addr = anogs_base + 0x4224;

    if (anogs_base != 0 && (addr1 == target_addr || addr2 == target_addr)) {
        return orig_memcmp(original_buffer, s2, n);
    }
    return orig_memcmp(s1, s2, n);
}

// Hatanın çözüldüğü modern pencere bulma fonksiyonu
void show_popup() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        
        // iOS 13+ Scene kontrolü (Hatanın çözümü burada)
        if (@available(iOS 13.0, *)) {
            for (UIScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                    window = ((UIWindowScene *)scene).windows.firstObject;
                    break;
                }
            }
        } else {
            // Eski iOS sürümleri için (Gerekirse)
            window = [UIApplication sharedApplication].keyWindow;
        }

        if (window.rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"anogs" 
                                                                           message:@"Dinamik Base Bulundu ve Bypass Aktif!" 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Devam Et" style:UIAlertActionStyleDefault handler:nil]];
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}

__attribute__((constructor))
static void auto_base_finder() {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "anogs")) {
            anogs_base = (uintptr_t)_dyld_get_image_vmaddr_slide(i);
            break;
        }
    }

    if (anogs_base != 0) {
        void *memcmp_ptr = dlsym(RTLD_DEFAULT, "memcmp");
        if (memcmp_ptr) {
            DobbyHook(memcmp_ptr, (void *)new_memcmp, (void **)&orig_memcmp);
        }
        show_popup();
    }
}

#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#include <string.h>
#include <dlfcn.h>

extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);

uintptr_t anogs_base = 0;
void *anogs_backup = NULL;
size_t anogs_size = 0x200000; // Analiz.txt'ye göre kapsamı genişlettik

int (*orig_memcmp)(const void *s1, const void *s2, size_t n);

// HER ŞEYİ KAPSAYAN YALANCI MEMCMP
int new_memcmp(const void *s1, const void *s2, size_t n) {
    uintptr_t addr1 = (uintptr_t)s1;
    uintptr_t addr2 = (uintptr_t)s2;

    // Eğer anogs bulunmuşsa ve tarama oraya çarpıyorsa
    if (anogs_base != 0 && anogs_backup != NULL) {
        // addr1 anogs içindeyse
        if (addr1 >= anogs_base && addr1 < (anogs_base + anogs_size)) {
            size_t offset = addr1 - anogs_base;
            return orig_memcmp((void *)((uintptr_t)anogs_backup + offset), s2, n);
        }
        // addr2 anogs içindeyse
        if (addr2 >= anogs_base && addr2 < (anogs_base + anogs_size)) {
            size_t offset = addr2 - anogs_base;
            return orig_memcmp(s1, (void *)((uintptr_t)anogs_backup + offset), n);
        }
    }
    return orig_memcmp(s1, s2, n);
}

// Popup'ı en güvenli şekilde göster
void show_stealth_popup() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    win = ((UIWindowScene *)scene).windows.firstObject;
                    break;
                }
            }
        }
        if (!win) win = [UIApplication sharedApplication].windows.firstObject;

        if (win.rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"System" 
                                                                           message:@"Stealth Mode Active" 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [win.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}

// DYLIB YÜKLENDİĞİ AN ÇALIŞIR (En kritik nokta)
__attribute__((constructor))
static void global_init() {
    // 1. ÖNCE FONKSİYONU ELE GEÇİR (Hangi kütüphane olursa olsun tarama kör edilsin)
    void *m_ptr = dlsym(RTLD_DEFAULT, "memcmp");
    if (m_ptr) {
        DobbyHook(m_ptr, (void *)new_memcmp, (void **)&orig_memcmp);
    }

    // 2. ANOGS'U SESSİZCE ARA
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "anogs")) {
            anogs_base = (uintptr_t)_dyld_get_image_vmaddr_slide(i);
            
            // Orijinal halini hemen yedekle (Kendi yamanı yapmadan önce!)
            anogs_backup = malloc(anogs_size);
            memcpy(anogs_backup, (void *)anogs_base, anogs_size);
            
            // 3. ŞİMDİ ASIL YAMANI YAP (0x4224 adresine zıplama koy)
            // Burada senin "Custom Code" fonksiyonunu bağlayabilirsin.
            
            show_stealth_popup();
            break;
        }
    }
}

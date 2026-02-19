#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#include <string.h>
#include <dlfcn.h>

// Dobby ve Sistem Fonksiyonları
extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);
extern "C" intptr_t _dyld_get_image_vmaddr_slide(uint32_t image_index);

// Analiz.txt dosyasındaki 0x4224 adresinin orijinal ilk 8 byte'ı
unsigned char original_buffer[8] = {0xFD, 0x7B, 0xBF, 0xA9, 0xFD, 0x03, 0x00, 0x91}; 

uintptr_t anogs_base = 0;
int (*orig_memcmp)(const void *s1, const void *s2, size_t n);

// Bütünlük Kontrolünü (Scanner) Kandıran Fonksiyon
int new_memcmp(const void *s1, const void *s2, size_t n) {
    uintptr_t addr1 = (uintptr_t)s1;
    uintptr_t addr2 = (uintptr_t)s2;
    
    // anogs_base her açılışta sistemden otomatik gelecek
    uintptr_t target_addr = anogs_base + 0x4224;

    if (anogs_base != 0 && (addr1 == target_addr || addr2 == target_addr)) {
        // Sistem kendi kodunu tararken ona orijinal byte'ları gösteriyoruz
        return orig_memcmp(original_buffer, s2, n);
    }
    return orig_memcmp(s1, s2, n);
}

// Ekrana Aktiflik Mesajı Basan Bölüm
void show_popup() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
        if (root) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"anogs" 
                                                                           message:@"Dinamik Base Bulundu ve Bypass Aktif!" 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Devam Et" style:UIAlertActionStyleDefault handler:nil]];
            [root presentViewController:alert animated:YES completion:nil];
        }
    });
}

__attribute__((constructor))
static void auto_base_finder() {
    // 1. SİSTEMDEN ANOGS'U BUL: İsmi küçük harf olan framework'ü tara
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "anogs")) {
            // Sistemdeki gerçek base adresini (slide) otomatik alıyoruz
            anogs_base = (uintptr_t)_dyld_get_image_vmaddr_slide(i);
            break;
        }
    }

    // 2. BYPASS'I UYGULA: Eğer framework bulunduysa kancaları at
    if (anogs_base != 0) {
        void *memcmp_ptr = dlsym(RTLD_DEFAULT, "memcmp");
        if (memcmp_ptr) {
            DobbyHook(memcmp_ptr, (void *)new_memcmp, (void **)&orig_memcmp);
        }
        
        // Aktif olduğunu anlaman için yazıyı göster
        show_popup();
    }
}

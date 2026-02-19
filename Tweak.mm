#import <UIKit/UIKit.h> // Pop-up için gerekli
#import <mach-o/dyld.h>
#include <string.h>
#include <dlfcn.h>

extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);

// Orijinal veriler (Analiz.txt 0x4224)
unsigned char original_buffer[8] = {0xFD, 0x7B, 0xBF, 0xA9, 0xFD, 0x03, 0x00, 0x91}; 

uintptr_t target_base = 0;
int (*orig_memcmp)(const void *s1, const void *s2, size_t n);

int new_memcmp(const void *s1, const void *s2, size_t n) {
    uintptr_t addr1 = (uintptr_t)s1;
    uintptr_t addr2 = (uintptr_t)s2;
    uintptr_t target_addr = target_base + 0x4224;

    if (addr1 == target_addr || addr2 == target_addr) {
        return orig_memcmp(original_buffer, s2, n);
    }
    return orig_memcmp(s1, s2, n);
}

// Ekrana uyarı mesajı basan fonksiyon
void show_alert() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Memory Patch" 
                                                                       message:@"Bypass ve Integrity Check Aktif!" 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
        [root presentViewController:alert animated:YES completion:nil];
    });
}

__attribute__((constructor))
static void setup_bypass() {
    // 0 index ana binary'yi (ShadowTrackerExtra) temsil eder
    target_base = (uintptr_t)_dyld_get_image_vmaddr_slide(0); 

    void *memcmp_ptr = dlsym(RTLD_DEFAULT, "memcmp");
    if (memcmp_ptr) {
        DobbyHook(memcmp_ptr, (void *)new_memcmp, (void **)&orig_memcmp);
    }
    
    // Aktif olduğunu anlaman için Pop-up göster
    show_alert();
}

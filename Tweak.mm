#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#include <string.h>
#include <dlfcn.h>
#include <stdint.h>

extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);

uintptr_t anogs_base = 0;
void *anogs_backup = NULL;
size_t anogs_size = 0x300000; 

int (*orig_memcmp)(const void *s1, const void *s2, size_t n);

// --- Düzeltilmiş Rapor Körleme ---
uint64_t (*orig_AnoSDKGetReportData3_0)();
uint64_t new_AnoSDKGetReportData3_0() {
    uint64_t v1_result = 0;
    if (orig_AnoSDKGetReportData3_0) {
        v1_result = orig_AnoSDKGetReportData3_0();
    }

    // Eğer veri döndüyse, sadece adresin geçerli olduğundan emin olup temizliyoruz
    if (v1_result > 0x100000000) { // Basit bir pointer geçerlilik kontrolü
        memset((void *)v1_result, 0, 8); 
    }

    return v1_result; 
}

// --- Derleme Hatasını Çözen Modern Popup ---
void show_stealth_popup() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        
        // iOS 13+ Scene-based window bulma
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                    window = ((UIWindowScene *)scene).windows.firstObject;
                    break;
                }
            }
        }
        
        // Eski iOS sürümleri veya Scene bulunamazsa yedek
        if (!window) {
            window = [UIApplication sharedApplication].windows.firstObject;
        }

        if (window && window.rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"System" 
                                                                           message:@"Stealth Mode Active" 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}

// Bütünlük Kontrolü (Aynı kalıyor)
int new_memcmp(const void *s1, const void *s2, size_t n) {
    uintptr_t addr1 = (uintptr_t)s1;
    uintptr_t addr2 = (uintptr_t)s2;
    if (anogs_base != 0 && anogs_backup != NULL) {
        if (addr1 >= anogs_base && addr1 < (anogs_base + anogs_size)) {
            size_t offset = addr1 - anogs_base;
            return orig_memcmp((void *)((uintptr_t)anogs_backup + offset), s2, n);
        }
        if (addr2 >= anogs_base && addr2 < (anogs_base + anogs_size)) {
            size_t offset = addr2 - anogs_base;
            return orig_memcmp(s1, (void *)((uintptr_t)anogs_backup + offset), n);
        }
    }
    return orig_memcmp(s1, s2, n);
}

__attribute__((constructor))
static void global_init() {
    void *m_ptr = dlsym(RTLD_DEFAULT, "memcmp");
    if (m_ptr) DobbyHook(m_ptr, (void *)new_memcmp, (void **)&orig_memcmp);

    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && (strstr(name, "anogs") || strstr(name, "ace_cs2"))) {
            anogs_base = (uintptr_t)_dyld_get_image_vmaddr_slide(i);
            anogs_backup = malloc(anogs_size);
            memcpy(anogs_backup, (void *)anogs_base, anogs_size);
            
            // Offsetini kontrol etmeyi unutma kanka (0x2DCC8)
            DobbyHook((void *)(anogs_base + 0x2DCC8), (void *)new_AnoSDKGetReportData3_0, (void **)&orig_AnoSDKGetReportData3_0);
            
            show_stealth_popup();
            break;
        }
    }
}

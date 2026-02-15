#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <mach-o/dyld.h>
#include <stdint.h>

// --- DOBBY HEADER TANIMI ---
#ifdef __cplusplus
extern "C" {
#endif
    int DobbyHook(void *function_address, void *replace_call, void **origin_call);
#ifdef __cplusplus
}
#endif

// --- CONFIG ---
#define TARGET_IMAGE "ShadowTrackerExtra"

// --- HOOK MANTIĞI ---
void *hook_AnoSDK_Report(void *arg1, void *arg2) {
    // Veri gönderimini keser ve boş döner
    return NULL; 
}

// --- BASE BULUCU ---
uintptr_t get_game_base() {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, TARGET_IMAGE)) {
            return (uintptr_t)_dyld_get_image_vmaddr_slide(i) + 0x100000000;
        }
    }
    return 0;
}

// --- ANA GİRİŞ ---
__attribute__((constructor))
static void entry() {
    // Oyunun tam yüklenmesi için 45 saniye bekle
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t base = get_game_base();
        if (base > 0x100000000) {
            
            // Pubg.txt'den gelen ofsetler
            // DelReportData ve SetReportData fonksiyonlarını susturuyoruz
            void *orig1;
            DobbyHook((void *)(base + 0x23874), (void *)hook_AnoSDK_Report, (void **)&orig1);
            
            void *orig2;
            DobbyHook((void *)(base + 0x23C74), (void *)hook_AnoSDK_Report, (void **)&orig2);
            
            NSLog(@"[DobbyBypass] Ofsetler Hooklandı: 0x23874, 0x23C74");
        }
    });
}

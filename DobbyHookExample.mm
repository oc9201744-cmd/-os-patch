#include "dobby.h"
#include <mach-o/dyld.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Pubg.txt'den gelen AnoSDK ofsetleri
#define ANO_OFFSET_1 0x23874
#define ANO_OFFSET_2 0x23C74

// Raporları durduracak sahte fonksiyon
void* fake_AnoSDK_Report(void* a1, void* a2) {
    // Burada NULL dönerek raporun sunucuya gitmesini engelliyoruz
    return nullptr; 
}

__attribute__((constructor))
static void initialize_onurcan_bypass() {
    // Lobi banını önlemek için 45 saniye gecikme
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // Oyunun ana modül adresini (Base) buluyoruz
        uintptr_t base = _dyld_get_image_vmaddr_slide(0) + 0x100000000;
        
        // Dobby ile Detour Hook atıyoruz
        DobbyHook((void*)(base + ANO_OFFSET_1), (void*)fake_AnoSDK_Report, nullptr);
        DobbyHook((void*)(base + ANO_OFFSET_2), (void*)fake_AnoSDK_Report, nullptr);
        
        NSLog(@"[Onurcan] Dobby: AnoSDK susturuldu (0x23874, 0x23C74)");
    });
}

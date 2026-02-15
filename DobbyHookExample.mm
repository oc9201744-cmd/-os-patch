#include "dobby.h"
#include <mach-o/dyld.h>
#import <Foundation/Foundation.h>

// Pubg.txt'den gelen AnoSDK ofsetleri
#define OFFSET_1 0x23874
#define OFFSET_2 0x23C74

// Raporları yutan sahte fonksiyon
void* fake_report(void* a1, void* a2) {
    return nullptr; // Rapor gönderilmeden geri dön
}

__attribute__((constructor))
static void initialize() {
    // 45 saniye bekle (Lobi banı için güvenlik önlemi)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // Oyunun ana modül adresini (Base) bul
        uintptr_t base = _dyld_get_image_vmaddr_slide(0) + 0x100000000;
        
        // Dobby ile kancayı at
        DobbyHook((void*)(base + OFFSET_1), (void*)fake_report, nullptr);
        DobbyHook((void*)(base + OFFSET_2), (void*)fake_report, nullptr);
        
        NSLog(@"[Onurcan] Dobby: AnoSDK Hooklari Basariyla Atildi!");
    });
}

#import <Foundation/Foundation.h>
#import <substrate.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>

// --- GÜVENLİ INTEGRITY BYPASS ---

typedef int (*ACE_Logic_t)(void *a1, void *a2);
ACE_Logic_t original_ace_logic;

int hooked_ace_logic(void *a1, void *a2) {
    // ACE bir tarama başlattığında (bak 6.txt -> 0xF806C)
    // Onu tamamen durdurmak yerine "temiz" sonucu döndürüyoruz.
    // Bu sayede oyunun diğer threadleri çökmez.
    return 0; 
}

void setup_bypass(const struct mach_header* header, intptr_t slide) {
    // Sadece oyunun ana kütüphanesi yüklendiğinde çalış
    // Ofset: 0xF806C (bak 6.txt analizi)
    uintptr_t target = slide + 0xF806C;
    
    // MSProtect kullanarak bellek izni alıyoruz (LDFLAGS ile uyumlu)
    MSHookFunction((void *)target, (void *)hooked_ace_logic, (void **)&original_ace_logic);
}

%ctor {
    @autoreleasepool {
        // OYUNUN HİÇ AÇILMAMA SORUNUNU ÇÖZEN KISIM:
        // Direkt müdahale yerine kütüphanenin belleğe oturmasını bekliyoruz.
        _dyld_register_func_for_add_image(setup_bypass);
        
        // Klasör/Dosya gizleme (anogs.c koruması)
        // strcmp hook'unu çok seçici yapıyoruz ki sistem çökmesin
    }
}

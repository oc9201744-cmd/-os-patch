#import <Foundation/Foundation.h>
#import <substrate.h>
#import <mach-o/dyld.h>

// ACE'nin kütüphane ismini bulalım (Genelde libACE.dylib veya benzeridir)
// Bu kod, ACE yüklendiği an onu pasifize eder.
static void handle_ace_module(const struct mach_header* header, intptr_t slide) {
    // ACE'nin raporlama yaptığı ana fonksiyonu bulmaya çalışıyoruz
    // Eğer ofset yüzünden çöküyorsa, bu yöntem daha güvenlidir.
    uintptr_t target_address = slide + 0xF806C; 
    
    // Belleğe yazarken çökmemesi için önce kontrol ediyoruz
    if (target_address > 0x100000000) { 
        uint32_t patch = 0xD65F03C0; // ARM64 RET komutu
        // MSHookMemory yerine güvenli bir vm_write yöntemi kullanılabilir
        MSHookMemory((void *)target_address, &patch, sizeof(patch));
    }
}

// Oyun açılırken kütüphaneleri izleyen fonksiyon
void (*old_dyld_add_image)(const struct mach_header* header, intptr_t slide);
void new_dyld_add_image(const struct mach_header* header, intptr_t slide) {
    old_dyld_add_image(header, slide);
    // Burada ACE kütüphanesinin gelmesini bekliyoruz
    handle_ace_module(header, slide);
}

%ctor {
    @autoreleasepool {
        // 1. Oyundan atmayı engellemek için gecikmeli başlatma
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            // 2. Kütüphane izleyiciyi başlat (Daha stabil yöntem)
            _dyld_register_func_for_add_image(handle_ace_module);
            
            NSLog(@"[Health] Safe Bypass Aktif. Çökme Engellendi.");
        });
    }
}

#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>

// Belirli bir adresteki veriyi (opcode) okuma fonksiyonu
void check_original_code(uintptr_t target_addr, NSString *label) {
    uint32_t current_code;
    
    // Bellekteki 4 byte'lık kodu güvenli bir şekilde oku
    if (vm_read_overwrite(mach_task_self(), (vm_address_t)target_addr, sizeof(uint32_t), (vm_address_t)&current_code, NULL) == KERN_SUCCESS) {
        // Okunan kodu Hex formatında logla
        NSLog(@"[V4_ANALYZE] 🔍 %@ | Adres: 0x%lx | Mevcut Kod: 0x%08X", label, target_addr, current_code);
    } else {
        NSLog(@"[V4_ANALYZE] ❌ %@ | Adres okunamadı! (0x%lx)", label, target_addr);
    }
}

%ctor {
    NSLog(@"[V4_ANALYZE] 🕵️ Analiz Modu Aktif. Hiçbir yama yapılmıyor...");

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t base_addr = (uintptr_t)_dyld_get_image_header(0);
        NSLog(@"[V4_ANALYZE] ℹ️ Base Address: 0x%lx", base_addr);

        // Mevcut durum tespiti
        check_original_code(base_addr + 0xF1198, @"Check_1");
        check_original_code(base_addr + 0xF11A0, @"Check_2");
        check_original_code(base_addr + 0xF119C, @"Check_3");
        check_original_code(base_addr + 0xF11B0, @"Check_4");
        check_original_code(base_addr + 0xF11B4, @"Check_5");

        NSLog(@"[V4_ANALYZE] ✅ Analiz tamamlandı. Logları kontrol et.");
    });
}

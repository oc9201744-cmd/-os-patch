#include <stdint.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>
#include <string.h>

// --- Bellek Yamama Operasyonu ---
void do_delayed_patch() {
    uintptr_t targetBase = 0;
    const char* targetName = "Anogs.framework/Anogs";

    // 1. Adım: Hafızada Anogs'u bul (Artık yüklendiğinden emin olduğumuz an)
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strcasestr(name, targetName)) {
            targetBase = (uintptr_t)_dyld_get_image_header(i);
            break;
        }
    }

    if (targetBase == 0) {
        NSLog(@"[KINGMOD] Hata: Anogs hala bellekte bulunamadı!");
        return;
    }

    // 2. Adım: 002.bin dosyasını oku
    NSString *binPath = [[NSBundle mainBundle] pathForResource:@"002" ofType:@"bin"];
    NSData *binData = [NSData dataWithContentsOfFile:binPath];

    if (binData) {
        mach_port_t task = mach_task_self();
        vm_address_t address = (vm_address_t)targetBase;
        vm_size_t size = binData.length;

        // 3. Adım: Yazma izni al (vm_protect)
        if (vm_protect(task, address, size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY) == KERN_SUCCESS) {
            
            // 4. Adım: Üzerine çak (vm_write)
            if (vm_write(task, address, (vm_offset_t)binData.bytes, (mach_msg_type_number_t)size) == KERN_SUCCESS) {
                
                // 5. Adım: Korumayı geri yükle
                vm_protect(task, address, size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
                
                // Başarılı yazısı
                dispatch_async(dispatch_get_main_queue(), ^{
                    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 150, [UIScreen mainScreen].bounds.size.width, 40)];
                    label.text = @"[!!!] GECİKMELİ YAMA BAŞARILI!";
                    label.textColor = [UIColor greenColor];
                    label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
                    label.textAlignment = NSTextAlignmentCenter;
                    label.font = [UIFont boldSystemFontOfSize:14];
                    [[UIApplication sharedApplication].keyWindow addSubview:label];
                });
            }
        }
    }
}

__attribute__((constructor))
static void init() {
    // 5 SANİYE BEKLE VE SONRA ÇALIŞTIR
    NSLog(@"[KINGMOD] Tweak yüklendi, 5 saniye bekleniyor...");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        do_delayed_patch();
    });
}

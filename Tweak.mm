#include <stdint.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <mach/mach.h>
#include <mach/vm_map.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>

// --- Ekrana Bilgi Basan Fonksiyon ---
void notify(NSString *msg, UIColor *color) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 150, [UIScreen mainScreen].bounds.size.width, 30)];
        label.text = msg;
        label.textColor = color;
        label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:14];
        [[UIApplication sharedApplication].keyWindow addSubview:label];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [label removeFromSuperview];
        });
    });
}

// --- ASIL OPERASYON: BELLEK YAMAMA ---
void perform_memory_patch() {
    uintptr_t targetBase = 0;
    
    // 1. Adım: Hafızada Anogs'un nerede olduğunu bul
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "Anogs.framework/Anogs")) {
            targetBase = (uintptr_t)_dyld_get_image_header(i);
            break;
        }
    }

    if (targetBase == 0) {
        notify(@"[HATA] ANOGS BELLEKTE BULUNAMADI!", [UIColor redColor]);
        return;
    }

    // 2. Adım: 002.bin dosyasını oku
    NSString *binPath = [[NSBundle mainBundle] pathForResource:@"002" ofType:@"bin"];
    NSData *binData = [NSData dataWithContentsOfFile:binPath];

    if (!binData) {
        notify(@"[HATA] 002.BIN DOSYASI YOK!", [UIColor orangeColor]);
        return;
    }

    // 3. Adım: BELLEK KORUMASINI KIR (VM_PROTECT)
    // Yazma izni alıyoruz (Read | Write | Execute)
    kern_return_t kr;
    mach_port_t task = mach_task_self();
    vm_address_t address = (vm_address_t)targetBase;
    vm_size_t size = binData.length;

    kr = vm_protect(task, address, size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    
    if (kr == KERN_SUCCESS) {
        // 4. Adım: VERİYİ ÜZERİNE YAZ (VM_WRITE)
        kr = vm_write(task, address, (vm_offset_t)binData.bytes, (mach_msg_type_number_t)size);
        
        if (kr == KERN_SUCCESS) {
            // 5. Adım: KORUMAYI ESKİ HALİNE GETİR
            vm_protect(task, address, size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
            notify(@"[BAŞARILI] 002.BIN BELLEĞE ÇAKILDI!", [UIColor greenColor]);
        } else {
            notify(@"[HATA] VM_WRITE BAŞARISIZ!", [UIColor redColor]);
        }
    } else {
        notify(@"[HATA] VM_PROTECT BAŞARISIZ!", [UIColor redColor]);
    }
}

__attribute__((constructor))
static void start() {
    // Oyunun kütüphaneyi yüklemesi için 5 saniye bekle
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        perform_memory_patch();
    });
}

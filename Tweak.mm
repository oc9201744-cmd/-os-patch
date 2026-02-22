#include <stdint.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <mach/mach.h>
#include <mach-o/dyld.h>

// --- Bellek Yamama Fonksiyonu (Parametreli) ---
void apply_patch_to_address(uintptr_t header, const char* name) {
    // Sadece Anogs'u hedef al
    if (strstr(name, "Anogs.framework/Anogs")) {
        
        NSString *binPath = [[NSBundle mainBundle] pathForResource:@"002" ofType:@"bin"];
        NSData *binData = [NSData dataWithContentsOfFile:binPath];

        if (binData) {
            mach_port_t task = mach_task_self();
            vm_address_t address = (vm_address_t)header;
            vm_size_t size = binData.length;

            // Korumayı aç (Read | Write | Copy)
            if (vm_protect(task, address, size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY) == KERN_SUCCESS) {
                
                // 002.bin içeriğini tam üzerine yaz
                if (vm_write(task, address, (vm_offset_t)binData.bytes, (mach_msg_type_number_t)size) == KERN_SUCCESS) {
                    
                    // Korumayı eski haline getir (Read | Execute)
                    vm_protect(task, address, size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
                    
                    // Ekranda Onay Mesajı
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 150, [UIScreen mainScreen].bounds.size.width, 40)];
                        label.text = @"[!!!] ANOGS YAKALANDI VE YAMALANDI!";
                        label.textColor = [UIColor greenColor];
                        label.backgroundColor = [UIColor blackColor];
                        label.textAlignment = NSTextAlignmentCenter;
                        [[UIApplication sharedApplication].keyWindow addSubview:label];
                    });
                }
            }
        }
    }
}

// --- Yeni Kütüphane Yüklendiğinde Çağrılan Callback ---
void on_image_load(const struct mach_header* mh, intptr_t vmaddr_slide) {
    Dl_info info;
    if (dladdr(mh, &info)) {
        apply_patch_to_address((uintptr_t)mh, info.dli_fname);
    }
}

__attribute__((constructor))
static void init() {
    // Sisteme diyoruz ki: "Bundan sonra ne yüklenirse bana haber ver"
    _dyld_register_func_for_add_image(on_image_load);
}

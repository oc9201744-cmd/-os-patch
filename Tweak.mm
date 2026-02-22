#include <stdint.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <mach/mach.h>
#include <mach/vm_map.h>
#include <mach-o/dyld.h>
#include <dlfcn.h> // Dl_info için bu ŞART!
#include <string.h>

// --- Bellek Yamama Fonksiyonu ---
void apply_patch_to_address(uintptr_t header, const char* name) {
    // Büyük/küçük harf duyarsız kontrol (Anogs yakalamak için)
    if (name && strcasestr(name, "Anogs.framework/Anogs")) {
        
        NSString *binPath = [[NSBundle mainBundle] pathForResource:@"002" ofType:@"bin"];
        NSData *binData = [NSData dataWithContentsOfFile:binPath];

        if (binData) {
            mach_port_t task = mach_task_self();
            vm_address_t address = (vm_address_t)header;
            vm_size_t size = binData.length;

            // 1. Korumayı aç (Read | Write | Copy)
            kern_return_t kr = vm_protect(task, address, size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
            
            if (kr == KERN_SUCCESS) {
                // 2. 002.bin içeriğini tam üzerine yaz (Memory Patch)
                if (vm_write(task, address, (vm_offset_t)binData.bytes, (mach_msg_type_number_t)size) == KERN_SUCCESS) {
                    
                    // 3. Korumayı eski haline getir (Read | Execute)
                    vm_protect(task, address, size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
                    
                    // Ekranda Onay Mesajı
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 150, [UIScreen mainScreen].bounds.size.width, 40)];
                        label.text = @"[!!!] ANOGS BELLEKTE YAMALANDI!";
                        label.textColor = [UIColor greenColor];
                        label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
                        label.textAlignment = NSTextAlignmentCenter;
                        label.font = [UIFont boldSystemFontOfSize:14];
                        label.layer.zPosition = 9999;
                        
                        UIWindow *window = nil;
                        if (@available(iOS 13.0, *)) {
                            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                                if (scene.activationState == UISceneActivationStateForegroundActive) {
                                    window = ((UIWindowScene*)scene).windows.firstObject;
                                    break;
                                }
                            }
                        } else { window = [UIApplication sharedApplication].keyWindow; }
                        [window addSubview:label];
                    });
                }
            }
        }
    }
}

// --- Yeni Kütüphane Yüklendiğinde Çağrılan Fonksiyon ---
void on_image_load(const struct mach_header* mh, intptr_t vmaddr_slide) {
    Dl_info info;
    // mh (header) adresinden dosya yolunu (name) buluyoruz
    if (dladdr(mh, &info)) {
        if (info.dli_fname != NULL) {
            apply_patch_to_address((uintptr_t)mh, info.dli_fname);
        }
    }
}

__attribute__((constructor))
static void init() {
    // Kütüphane yüklemelerini izlemeye al
    _dyld_register_func_for_add_image(on_image_load);
}

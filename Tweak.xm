#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <mach/vm_map.h>

// --- Bellek Yama Fonksiyonu ---
// Jailbreak'siz cihazlarda vm_protect her zaman çalışmayabilir, 
// ancak doğru entitlement'lar ile (get-task-allow) şansı yüksektir.
BOOL apply_patch_at_address(uintptr_t addr, uint32_t instruction) {
    mach_port_t task = mach_task_self();
    vm_address_t page_start = trunc_page(addr);
    vm_size_t page_size = vm_kernel_page_size;

    // Yazma izni al (Copy-on-Write)
    kern_return_t kr = vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (kr != KERN_SUCCESS) {
        return NO;
    }

    // Instruction'ı değiştir
    *(uint32_t *)addr = instruction;

    // İzinleri eski haline döndür
    vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    return YES;
}

// --- Bildirim Sistemi ---
void show_baybars_msg(NSString *msg) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                window = ((UIWindowScene *)scene).windows.firstObject;
                break;
            }
        }
        if (!window) window = [UIApplication sharedApplication].keyWindow;
        if (!window) return;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 260, 40)];
        label.center = CGPointMake(window.frame.size.width / 2, 110);
        label.text = msg;
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [[UIColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:0.8] copy];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:14];
        label.layer.cornerRadius = 10;
        label.clipsToBounds = YES;
        [window addSubview:label];

        [UIView animateWithDuration:0.5 delay:4.0 options:0 animations:^{ label.alpha = 0; } completion:^(BOOL f){ [label removeFromSuperview]; }];
    });
}

// --- Main Hook ---
static void handle_image_load(const struct mach_header *mh, intptr_t slide) {
    const char *path = dyld_image_path_containing_address(mh);
    
    // Framework ismini yakalıyoruz
    if (path && (strstr(path, "Anogs.framework") || strstr(path, "Anogs"))) {
        
        /* Görüntüdeki Analiz:
           loc_D3844: TST W9, #0xFF
           B.EQ loc_D3858
           
           Yapılacak Patch:
           Koşulu tamamen devre dışı bırakıp W1 register'ına istediğimiz 
           güvenli değeri (örneğin 0xC0) zorla yazıyoruz.
        */
        
        uintptr_t target_offset = 0xD3844; 
        uintptr_t final_addr = slide + target_offset;
        
        // MOV W1, #0xC0 (ARM64: 0x52801801)
        uint32_t patch_instruction = 0x52801801; 

        if (apply_patch_at_address(final_addr, patch_instruction)) {
            show_baybars_msg(@"Baybars Bypass: Active ✅");
        } else {
            show_baybars_msg(@"Baybars Bypass: Permission Denied ❌");
        }
    }
}

__attribute__((constructor))
static void baybars_init() {
    // Uygulama her kütüphane yüklediğinde tetiklenir
    _dyld_register_func_for_add_image(&handle_image_load);
}

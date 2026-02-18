#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h> // iOS'un öz kütüphanesi

// --- BELLEK YAZMA FONKSİYONU (Jailbreak Gerektirmez) ---
void patchOffset(uintptr_t address, uint32_t data) {
    mach_port_t task = mach_task_self();
    kern_return_t kr;
    
    // Sayfa korumasını kaldır (Yazılabilir yap)
    kr = vm_protect(task, (vm_address_t)address, sizeof(data), FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (kr == KERN_SUCCESS) {
        // Veriyi yaz (Örn: MOV X0, #0 / RET)
        *(uint32_t *)address = data;
        // Korumayı geri yükle
        vm_protect(task, (vm_address_t)address, sizeof(data), FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    }
}

// --- BAYBARS MESAJ SİSTEMİ ---
void BaybarsMesaj(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                window = ((UIWindowScene *)scene).windows.firstObject;
                break;
            }
        }
        if (!window) return;
        
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 40)];
        l.center = CGPointMake(window.frame.size.width / 2, 100);
        l.text = msg;
        l.textColor = [UIColor greenColor];
        l.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        l.textAlignment = NSTextAlignmentCenter;
        l.layer.cornerRadius = 10;
        l.clipsToBounds = YES;
        [window addSubview:l];
        [UIView animateWithDuration:0.5 delay:4.0 options:0 animations:^{ l.alpha = 0; } completion:^(BOOL f){ [l removeFromSuperview]; }];
    });
}

void setupHooks() {
    uintptr_t slide = (uintptr_t)_dyld_get_image_vmaddr_slide(0);
    
    // --- RETURN 0 PATCH (MOV X0, #0 / RET) ---
    // ARM64 için 'MOV X0, #0' komutu: 0x000080D2
    // ARM64 için 'RET' komutu: 0xC0035FD6
    
    // 0x2DF68 ofsetini sustur (Fonksiyonun en başına RET çakıyoruz)
    patchOffset(slide + 0x2DF68, 0xD65F03C0); 
    
    // 0xF806C ofsetini sustur
    patchOffset(slide + 0xF806C, 0xD65F03C0);

    BaybarsMesaj(@"Baybars: Memory Patch Aktif!");
}

__attribute__((constructor))
static void initialize() {
    // Oyunun lobiye girmesini bekle (iOS 17 Güvenliği için)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        setupHooks();
    });
}

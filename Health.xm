#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach_init.h>
#import <mach/vm_map.h>
#import <dlfcn.h>

// Artık substrate.h gerekmiyor, tamamen sistem fonksiyonlarıyla çalışacağız.

// ---- BaybarsMesaj (UI Bildirimi) ----
void BaybarsMesaj(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        // Modern iOS (SceneDelegate) uyumluluğu
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                window = ((UIWindowScene *)scene).windows.firstObject;
                break;
            }
        }
        if (!window) window = [UIApplication sharedApplication].keyWindow;
        if (!window) return;

        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 280, 45)];
        l.center = CGPointMake(window.frame.size.width / 2, 150);
        l.text = msg;
        l.textColor = [UIColor whiteColor];
        l.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.9];
        l.textAlignment = NSTextAlignmentCenter;
        l.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        l.layer.cornerRadius = 10;
        l.clipsToBounds = YES;
        [window addSubview:l];

        [UIView animateWithDuration:0.5 delay:4.0 options:0 animations:^{ l.alpha = 0; } completion:^(BOOL f){ [l removeFromSuperview]; }];
    });
}

// ---- Bellek Yazma (Native vm_protect) ----
void patch_function(void* address, uint32_t new_instruction) {
    kern_return_t kr;
    mach_port_t task = mach_task_self();
    vm_address_t addr = (vm_address_t)address;
    
    // Yazma izni ver
    kr = vm_protect(task, addr, sizeof(uint32_t), FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (kr != KERN_SUCCESS) return;

    *(uint32_t*)address = new_instruction;

    // İzinleri eski haline getir (Sadece Read ve Execute)
    vm_protect(task, addr, sizeof(uint32_t), FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
}

// ---- Desen Arama ----
static uint8_t* find_pattern(uint8_t* start, size_t max_len, const uint8_t* pattern, size_t pattern_len) {
    for (size_t i = 0; i <= max_len - pattern_len; i++) {
        if (memcmp(start + i, pattern, pattern_len) == 0) {
            return start + i;
        }
    }
    return NULL;
}

// ---- Patch Uygulayıcı ----
void apply_patch(const struct mach_header *mh, intptr_t slide) {
    // sub_201488 fonksiyonunun çalışma zamanı adresi
    uintptr_t func_start = slide + 0x201488;

    // CMP W0, #0 ve MOV W8, #4 desenini arıyoruz
    const uint8_t pattern[] = {
        0x1F, 0x00, 0x00, 0x71, 
        0x88, 0x00, 0x80, 0x52
    };

    uint8_t* found = find_pattern((uint8_t*)func_start, 0x2000, pattern, sizeof(pattern));
    
    if (found) {
        // Bulunan desenin hemen 8 byte sonrasındaki CSEL'i MOV W20, #0 yap
        uint8_t* target_addr = found + 8;
        patch_function(target_addr, 0x52800014); // MOV W20, #0
        
        BaybarsMesaj(@"[Baybars] Fix Aktif Edildi!");
    } else {
        // Eğer slide yanlışsa veya offset değiştiyse tüm imajda ara
        BaybarsMesaj(@"[Baybars] Desen bulunamadı, bekleniyor...");
    }
}

// ---- Library Takibi ----
static void image_added(const struct mach_header *mh, intptr_t vmaddr_slide) {
    const char* image_name = _dyld_get_image_name(0); // Örnek amaçlı, gerçek isim kontrolü aşağıda
    
    // Yüklenen her kütüphanenin ismine bakıyoruz
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "libanogs.dylib")) {
            intptr_t slide = _dyld_get_image_vmaddr_slide(i);
            apply_patch(mh, slide);
            break; 
        }
    }
}

// ---- Giriş Noktası (Constructor) ----
__attribute__((constructor))
static void initialize() {
    // Jailbreak bağımlılığı yok, direkt dyld register kullanıyoruz.
    _dyld_register_func_for_add_image(&image_added);
}

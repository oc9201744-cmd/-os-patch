#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <mach/mach_init.h>
#import <mach/vm_map.h>
#import <substrate.h>  // CydiaSubstrate

// ---- BaybarsMesaj (opsiyonel, hata ayıklama için) ----
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

        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 50)];
        l.center = CGPointMake(window.frame.size.width / 2, 120);
        l.text = msg;
        l.textColor = [UIColor yellowColor];
        l.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
        l.textAlignment = NSTextAlignmentCenter;
        l.font = [UIFont boldSystemFontOfSize:15];
        l.layer.cornerRadius = 12;
        l.clipsToBounds = YES;
        [window addSubview:l];

        [UIView animateWithDuration:0.5 delay:5.0 options:0 animations:^{ l.alpha = 0; } completion:^(BOOL f){ [l removeFromSuperview]; }];
    });
}

// ---- Bellek yazma fonksiyonu (verdiğin gibi) ----
void patch_function(void* address, uint32_t new_instruction) {
    vm_protect(mach_task_self(), (vm_address_t)address, sizeof(uint32_t), 0, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE);
    *(uint32_t*)address = new_instruction;
    vm_protect(mach_task_self(), (vm_address_t)address, sizeof(uint32_t), 0, VM_PROT_EXECUTE);
}

// ---- Desen arama fonksiyonu ----
// Verilen başlangıç adresinden itibaren maksimum max_len byte içinde
// sırayla aranan byte dizisini (pattern) bulur. Bulduğu adresi döndürür, yoksa NULL.
static uint8_t* find_pattern(uint8_t* start, size_t max_len, const uint8_t* pattern, size_t pattern_len) {
    for (size_t i = 0; i <= max_len - pattern_len; i++) {
        if (memcmp(start + i, pattern, pattern_len) == 0) {
            return start + i;
        }
    }
    return NULL;
}

// ---- Patch uygulayıcı ----
void apply_patch() {
    // 1. libanogs.dylib'in slide'ını bul
    uintptr_t slide = 0;
    const char *target_lib = "libanogs.dylib"; // .so da olabilir, kontrol et
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, target_lib)) {
            slide = _dyld_get_image_vmaddr_slide(i);
            break;
        }
    }
    if (slide == 0) {
        BaybarsMesaj(@"libanogs.dylib bulunamadı!");
        return;
    }

    // 2. sub_201488 fonksiyonunun başlangıç adresi
    uintptr_t func_start = slide + 0x201488;

    // 3. Arayacağımız desen:
    //    CMP W0, #0  (0x7100001F)
    //    MOV W8, #4  (0x52800088)
    //    CSEL W20, WZR, W8, NE (tahmini: 0xD40813F4, little-endian: F4 13 08 D4)
    // Ama CSEL'in tam opcode'u değişebilir, bu yüzden sadece ilk iki talimatı arayıp
    // onların hemen ardındaki 4 byte'ı değiştireceğiz.
    const uint8_t pattern[] = {
        0x1F, 0x00, 0x00, 0x71,  // CMP W0, #0  (little-endian)
        0x88, 0x00, 0x80, 0x52   // MOV W8, #4  (little-endian)
    };
    size_t pattern_len = sizeof(pattern);

    // 4. Arama alanını belirle (fonksiyonun ilk 0x1000 byte'ı yeterlidir)
    uint8_t* search_start = (uint8_t*)func_start;
    size_t search_size = 0x1000;

    uint8_t* found = find_pattern(search_start, search_size, pattern, pattern_len);
    if (!found) {
        BaybarsMesaj(@"Desen bulunamadı!");
        return;
    }

    // 5. CSEL talimatının adresi = found + pattern_len (yani 8 byte sonrası)
    uint8_t* csel_addr = found + pattern_len;

    // 6. CSEL'i MOV W20, #0 (0x52800014) ile değiştir
    uint32_t new_instr = 0x52800014;  // MOV W20, #0
    patch_function(csel_addr, new_instr);

    BaybarsMesaj(@"Ban fix başarıyla uygulandı!");
}

// ---- Library load hook'u ----
static void image_added(const struct mach_header *mh, intptr_t vmaddr_slide) {
    // Her yeni image yüklendiğinde çağrılır
    const char* name = dyld_image_path_containing_address(mh);
    if (name && strstr(name, "libanogs.dylib")) {
        // libanogs yüklendi, patch'i uygula
        apply_patch();
    }
}

// ---- Constructor (tweak yüklendiğinde çalışır) ----
__attribute__((constructor))
static void initialize() {
    // BaybarsMesaj hemen çalışmaz çünkə UI henüz yok, 5 saniye gecikmeyle dene
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BaybarsMesaj(@"Tweak yüklendi, libanogs bekleniyor...");
    });

    // libanogs yüklendiğinde apply_patch'i çağıracak fonksiyonu kaydet
    _dyld_register_func_for_add_image(&image_added);
}
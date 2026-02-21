#import <UIKit/UIKit.h>
#import <substrate.h>
#import <mach-o/dyld.h>

#ifdef __cplusplus
extern "C" {
#endif
    int DobbyCodePatch(void *address, uint8_t *buffer, uint32_t buffer_size);
#ifdef __cplusplus
}
#endif

void apply_dobby_patch_debug(uintptr_t target_addr, NSString *label) {
    uint8_t nop_bytes[] = {0x1F, 0x20, 0x03, 0xD5}; 
    
    int result = DobbyCodePatch((void *)target_addr, nop_bytes, 4);
    
    if (result == 0) {
        // Boşluksuz %@ formatı
        NSLog(@"[V4_DEBUG] ✅ %@ Başarıyla Yamalandı! Adres: 0x%lx", label, target_addr);
    } else {
        NSLog(@"[V4_DEBUG] ❌ %@ YAMALANAMADI! Hata Kodu: %d Adres: 0x%lx", label, result, target_addr);
    }
}

void show_debug_toast(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        }
        if (!window) window = [UIApplication sharedApplication].windows.firstObject;
        
        if (window) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(window.frame.size.width/4, window.frame.size.height - 100, window.frame.size.width/2, 35)];
            label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
            label.textColor = [UIColor whiteColor];
            label.textAlignment = NSTextAlignmentCenter;
            label.text = msg;
            label.font = [UIFont systemFontOfSize:12];
            label.layer.cornerRadius = 10;
            label.clipsToBounds = YES;
            [window addSubview:label];
            
            [UIView animateWithDuration:4.0 animations:^{ label.alpha = 0; } completion:^(BOOL finished){ [label removeFromSuperview]; }];
        }
    });
}

%ctor {
    NSLog(@"[V4_DEBUG] 🔥 Bypass Başlatılıyor...");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t base_addr = (uintptr_t)_dyld_get_image_header(0);
        NSLog(@"[V4_DEBUG] ℹ️ Base Address: 0x%lx", base_addr);

        apply_dobby_patch_debug(base_addr + 0xF1198, @"Anogs_Check_1");
        apply_dobby_patch_debug(base_addr + 0xF11A0, @"Anogs_Check_2");
        apply_dobby_patch_debug(base_addr + 0xF119C, @"Anogs_Check_3");
        apply_dobby_patch_debug(base_addr + 0xF11B0, @"Anogs_Check_4");
        apply_dobby_patch_debug(base_addr + 0xF11B4, @"Anogs_Check_5");

        show_debug_toast(@"[V4] Tüm Yamalar İşlendi!");
    });
}

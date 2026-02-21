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

void show_v4_toast(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
        if (window) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(window.frame.size.width/4, 150, window.frame.size.width/2, 40)];
            label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
            label.textColor = [UIColor cyanColor];
            label.textAlignment = NSTextAlignmentCenter;
            label.text = msg;
            label.font = [UIFont boldSystemFontOfSize:13];
            label.layer.cornerRadius = 15;
            label.clipsToBounds = YES;
            [window addSubview:label];
            [UIView animateWithDuration:5.0 animations:^{ label.alpha = 0; } completion:^(BOOL finished){ [label removeFromSuperview]; }];
        }
    });
}

%ctor {
    NSLog(@"[V4_DEBUG] 🛠️ Patching 0x371E0 with MOV X0, #0...");

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t base_addr = (uintptr_t)_dyld_get_image_header(0);
        uintptr_t target_addr = base_addr + 0x371E0; 

        // MOV X0, #0 (00 00 80 D2) ve RET (C0 03 5F D6)
        uint8_t zero_patch[] = {0x00, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6}; 
        
        int result = DobbyCodePatch((void *)target_addr, zero_patch, 8);
        
        if (result == 0) {
            NSLog(@"[V4_DEBUG] ✅ Patch Basarili (X0=0): 0x371E0");
            show_v4_toast(@"Patch Aktif: MOV X0, #0");
        } else {
            NSLog(@"[V4_DEBUG] ❌ Patch Hatasi! Kod: %d", result);
        }
    });
}

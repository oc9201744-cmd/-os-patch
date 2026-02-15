#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>
#include <sys/mman.h>

// --- INTERPOSE ALTYAPISI ---
typedef struct interpose_substitution {
    const void* replacement;
    const void* original;
} interpose_substitution_t;

#define INTERPOSE_FUNCTION(replacement, original) \
    __attribute__((used)) static const interpose_substitution_t interpose_##replacement \
    __attribute__((section("__DATA,__interpose"))) = { (const void*)(unsigned long)&replacement, (const void*)(unsigned long)&original }

// --- SISTEM HOOKLARI ---
extern "C" int ptrace(int request, int pid, void* addr, int data);
int h_ptrace(int request, int pid, void* addr, int data) { return 0; }
INTERPOSE_FUNCTION(h_ptrace, ptrace);

int h_strcmp(const char *s1, const char *s2) {
    if (s2 != NULL && (strstr(s2, "anti_sp2s") || strstr(s2, "libanogs"))) return 1;
    return strcmp(s1, s2);
}
INTERPOSE_FUNCTION(h_strcmp, strcmp);

// --- GÖRSEL MÜHÜR (Security Onur Can) ---
void show_onur_can_ui() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        } else {
            window = [UIApplication sharedApplication].keyWindow;
        }

        if (window) {
            // Üst Bar Bildirimi
            UILabel *onurCanLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, window.frame.size.width, 30)];
            onurCanLabel.text = @"🛡️ Security Onur Can - Active";
            onurCanLabel.textColor = [UIColor whiteColor];
            onurCanLabel.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.7];
            onurCanLabel.textAlignment = NSTextAlignmentCenter;
            onurCanLabel.font = [UIFont boldSystemFontOfSize:14];
            onurCanLabel.layer.shadowColor = [UIColor blackColor].CGColor;
            onurCanLabel.layer.shadowOffset = CGSizeMake(2, 2);
            onurCanLabel.layer.shadowOpacity = 1.0;
            [window addSubview:onurCanLabel];

            // Pop-up Uyarı
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"SECURITY ONUR CAN" 
                                       message:@"ACE Analiz ve Bypass Tamamlandı.\nSistem Koruma Altında!" 
                                       preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Gazla Kanka!" style:UIAlertActionStyleDefault handler:nil]];
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}

// --- ACE PATCH FONKSİYONU ---
void apply_ace_patches() {
    uintptr_t base = 0;
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char* name = _dyld_get_image_name(i);
        if (name && (strstr(name, "anogs") || i == 0)) {
            base = (uintptr_t)_dyld_get_image_header(i);
            
            // F012C -> RET
            uintptr_t target1 = base + 0xF012C;
            mprotect((void *)(target1 & ~0xFFF), 0x1000, 7);
            *(uint32_t *)target1 = 0xD65F03C0; 

            // F838C -> RET
            uintptr_t target2 = base + 0xF838C;
            mprotect((void *)(target2 & ~0xFFF), 0x1000, 7);
            *(uint32_t *)target2 = 0xD65F03C0;

            // 11D85C -> MOV X0, #1 / RET
            uintptr_t target3 = base + 0x11D85C;
            mprotect((void *)(target3 & ~0xFFF), 0x1000, 7);
            *(uint32_t *)target3 = 0xD2800020; 
            *(uint32_t *)(target3 + 4) = 0xD65F03C0; 
        }
    }
}

// --- BAŞLATICI ---
__attribute__((constructor))
static void init() {
    // 45 saniye gecikme ile hem ACE yamaları hem de Onur Can yazısı devreye girer
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        apply_ace_patches();
        show_onur_can_ui();
    });
}

#include <stdio.h>
#include <string.h>
#include <dlfcn.h>
#include <stdint.h>
#include <sys/mman.h>
#include <mach-o/dyld.h>
#include <UIKit/UIKit.h>

// --- Interpose Altyapısı ---
typedef struct interpose_substitution {
    const void* replacement;
    const void* original;
} interpose_substitution_t;

#define INTERPOSE_FUNCTION(replacement, original) \
    __attribute__((used)) static const interpose_substitution_t interpose_##replacement \
    __attribute__((section("__DATA,__interpose"))) = { (const void*)(unsigned long)&replacement, (const void*)(unsigned long)&original }

// --- 1. GÖRSEL BİLDİRİM (UI) ---
void draw_bypass_status() {
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
            UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 60, 180, 25)];
            statusLabel.text = @"[XO] BYPASS ACTIVE";
            statusLabel.textColor = [UIColor whiteColor];
            statusLabel.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.6];
            statusLabel.textAlignment = NSTextAlignmentCenter;
            statusLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
            statusLabel.layer.cornerRadius = 10;
            statusLabel.clipsToBounds = YES;
            
            [window addSubview:statusLabel];
            
            // 10 saniye sonra yazıyı yavaşça kaybet (isteğe bağlı)
            [UIView animateWithDuration:2.0 delay:10.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                statusLabel.alpha = 0;
            } completion:^(BOOL finished) {
                [statusLabel removeFromSuperview];
            }];
        }
    });
}

// --- 2. SİSTEM HOOKLARI ---
extern "C" int ptrace(int request, int pid, void* addr, int data);
int my_ptrace(int request, int pid, void* addr, int data) { return 0; }
INTERPOSE_FUNCTION(my_ptrace, ptrace);

int my_strcmp(const char *s1, const char *s2) {
    if (s2 != NULL && strstr(s2, "anti_sp2s")) return 0;
    return strcmp(s1, s2);
}
INTERPOSE_FUNCTION(my_strcmp, strcmp);

int my_mprotect(void *addr, size_t len, int prot) { return mprotect(addr, len, 7); }
INTERPOSE_FUNCTION(my_mprotect, mprotect);

// --- 3. HAFIZA YAMALARI (OFFSET) ---
void patch_memory(const char* module, uintptr_t offset) {
    uintptr_t base = 0;
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        if (strstr(_dyld_get_image_name(i), module)) {
            base = (uintptr_t)_dyld_get_image_header(i);
            break;
        }
    }
    if (base != 0) {
        uintptr_t target = base + offset;
        mprotect((void *)(target & ~0xFFF), 0x1000, 7);
        *(uint32_t *)target = 0xD65F03C0; // ARM64 RET
    }
}

// --- BAŞLATICI ---
__attribute__((constructor))
static void initialize() {
    // Oyun açıldıktan 6 saniye sonra hem yazıyı koy hem yamaları yap
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        draw_bypass_status(); // Ekrana yazıyı bas
        
        patch_memory("anogs", 0xF012C); 
        patch_memory("anogs", 0x2DD28);
        patch_memory("anogs", 0x80927);
        
        printf("[XO] Her şey hazır kanka! 🔥\n");
    });
}

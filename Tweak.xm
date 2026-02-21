#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>

// Dobby'yi en yalın haliyle tanıtıyoruz
#ifdef __cplusplus
extern "C" {
#endif
    int DobbyHook(void *address, void *replace_call, void **origin_call);
    int DobbyCodePatch(void *address, uint8_t *buffer, uint32_t buffer_size);
#ifdef __cplusplus
}
#endif

// Mesaj Basma Fonksiyonu
void show_v5_alert(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
        if (window.rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"V5 BYPASS" 
                                                                           message:msg 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}

// Hooklar ve Orijinalleri
static int (*orig_sub_19D98)(void* a1, void* a2);
int hook_sub_19D98(void* a1, void* a2) { return 0; }

static void* (*orig_sub_10C24)(void* a1);
void* hook_sub_10C24(void* a1) { return orig_sub_10C24(a1); }

static void (*orig_sub_19DF8)(void);
void hook_sub_19DF8(void) { return; }

static void (*orig_sub_4A130)(void);
void hook_sub_4A130(void) { return; }

// --- Ana Başlatıcı ---
// %ctor yerine __attribute__((constructor)) kullanarak Substrate bağımlılığını iyice azaltıyoruz
__attribute__((constructor))
static void initialize_bypass() {
    // Bu log gelirse dylib başarıyla yüklenmiştir
    NSLog(@"[V5_LOG] Dylib sisteme girdi!");

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t base = (uintptr_t)_dyld_get_image_header(0);

        // ASLR + Hooklar
        DobbyHook((void*)(base + 0x19D98), (void*)hook_sub_19D98, (void**)&orig_sub_19D98);
        DobbyHook((void*)(base + 0x10C24), (void*)hook_sub_10C24, (void**)&orig_sub_10C24);
        DobbyHook((void*)(base + 0x19DF8), (void*)hook_sub_19DF8, (void**)&orig_sub_19DF8);
        DobbyHook((void*)(base + 0x4A130), (void*)hook_sub_4A130, (void**)&orig_sub_4A130);

        // Byte Patch
        uint8_t zero_ret[] = {0x00, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6}; 
        DobbyCodePatch((void*)(base + 0x371E0), zero_ret, 8);

        show_v5_alert(@"V5 BYPASS: AKTİF ✅");
    });
}

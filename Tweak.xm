#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>

#ifdef __cplusplus
extern "C" {
#endif
    int DobbyHook(void *address, void *replace_call, void **origin_call);
    int DobbyCodePatch(void *address, uint8_t *buffer, uint32_t buffer_size);
#ifdef __cplusplus
}
#endif

// --- ASLR Hesaplama Yardımcısı ---
uintptr_t get_actual_addr(uintptr_t offset) {
    // _dyld_get_image_header(0) ana binary'nin (oyunun) başlangıç adresini verir.
    uintptr_t base = (uintptr_t)_dyld_get_image_header(0);
    return base + offset;
}

// --- Mesaj Basma ---
void show_v5_alert(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
        if (window.rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"V5 BYPASS" 
                                                                           message:msg 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        } else {
            // UI hazır değilse 2 saniye sonra tekrar dene
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                show_v5_alert(msg);
            });
        }
    });
}

// --- Hooklar ---
static int (*orig_sub_19D98)(void* a1, void* a2);
int hook_sub_19D98(void* a1, void* a2) { return 0; }

static void* (*orig_sub_10C24)(void* a1);
void* hook_sub_10C24(void* a1) { return orig_sub_10C24(a1); }

static void (*orig_sub_19DF8)(void);
void hook_sub_19DF8(void) { return; }

static void (*orig_sub_4A130)(void);
void hook_sub_4A130(void) { return; }

static void (*orig_sub_19F54)(void* a1, void* a2, size_t a3);
void hook_sub_19F54(void* a1, void* a2, size_t a3) { return; }

static void (*orig_sub_19F64)(void* a1);
void hook_sub_19F64(void* a1) { return; }

// --- Ana Başlatıcı ---
%ctor {
    NSLog(@"[V5_DEBUG] Dylib yüklendi, ASLR hesaplanıyor...");

    // UI'ın ve binary'nin tam oturması için 5 saniye bekle
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // ASLR + Offset hesaplamalarıyla Hooklar
        DobbyHook((void*)get_actual_addr(0x19D98), (void*)hook_sub_19D98, (void**)&orig_sub_19D98);
        DobbyHook((void*)get_actual_addr(0x10C24), (void*)hook_sub_10C24, (void**)&orig_sub_10C24);
        DobbyHook((void*)get_actual_addr(0x19DF8), (void*)hook_sub_19DF8, (void**)&orig_sub_19DF8);
        DobbyHook((void*)get_actual_addr(0x4A130), (void*)hook_sub_4A130, (void**)&orig_sub_4A130);
        DobbyHook((void*)get_actual_addr(0x19F54), (void*)hook_sub_19F54, (void**)&orig_sub_19F54);
        DobbyHook((void*)get_actual_addr(0x19F64), (void*)hook_sub_19F64, (void**)&orig_sub_19F64);

        // Özel Byte Patch (371E0)
        uint8_t zero_ret[] = {0x00, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6}; 
        DobbyCodePatch((void*)get_actual_addr(0x371E0), zero_ret, 8);

        NSLog(@"[V5_DEBUG] Tüm hooklar ASLR ile başarıyla uygulandı.");
        show_v5_alert(@"ASLR Bypass Aktif!\nOyun Başlatıldı.");
    });
}

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>

// Dobby fonksiyonlarını C++ mangling hatası almadan tanımlıyoruz
#ifdef __cplusplus
extern "C" {
#endif
    int DobbyHook(void *address, void *replace_call, void **origin_call);
    int DobbyCodePatch(void *address, uint8_t *buffer, uint32_t buffer_size);
#ifdef __cplusplus
}
#endif

/**
 * V5 SAFE BYPASS - CRASH FIX VERSION
 */

// --- Hook Tanımlamaları ---

static int (*orig_sub_19D98)(void* a1, void* a2);
int hook_sub_19D98(void* a1, void* a2) {
    // Jailbreak kontrolünü her zaman temiz (0) döndür
    return 0; 
}

static void* (*orig_sub_10C24)(void* a1);
void* hook_sub_10C24(void* a1) {
    // CRASH FIX: NULL döndürmek yerine orijinali çağırarak veri akışını bozma
    return orig_sub_10C24(a1);
}

static void (*orig_sub_19DF8)(void);
void hook_sub_19DF8(void) {
    // Oyunun kapanma (Exit) komutunu yut
    return;
}

static void (*orig_sub_4A130)(void);
void hook_sub_4A130(void) {
    // Raporlama fonksiyonunu sustur
    return;
}

static void (*orig_sub_19F54)(void* a1, void* a2, size_t a3);
void hook_sub_19F54(void* a1, void* a2, size_t a3) { 
    // Bütünlük kontrolü bypass
    return; 
}

static void (*orig_sub_19F64)(void* a1);
void hook_sub_19F64(void* a1) { 
    return; 
}

// --- Başlatıcı ---

%ctor {
    // ASLR Slide değerini al
    intptr_t slide = _dyld_get_image_vmaddr_slide(0);

    // Kritik Fonksiyon Hookları
    DobbyHook((void*)(slide + 0x19D98), (void*)hook_sub_19D98, (void**)&orig_sub_19D98);
    DobbyHook((void*)(slide + 0x10C24), (void*)hook_sub_10C24, (void**)&orig_sub_10C24);
    DobbyHook((void*)(slide + 0x19DF8), (void*)hook_sub_19DF8, (void**)&orig_sub_19DF8);
    DobbyHook((void*)(slide + 0x4A130), (void*)hook_sub_4A130, (void**)&orig_sub_4A130);
    DobbyHook((void*)(slide + 0x19F54), (void*)hook_sub_19F54, (void**)&orig_sub_19F54);
    DobbyHook((void*)(slide + 0x19F64), (void*)hook_sub_19F64, (void**)&orig_sub_19F64);

    // Byte Patch (MOV X0, #0; RET)
    uintptr_t target_371E0 = slide + 0x371E0;
    uint8_t zero_ret[] = {0x00, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6}; 
    
    // Patch işlemini güvenli bir şekilde uygula
    DobbyCodePatch((void*)target_371E0, zero_ret, 8);

    NSLog(@"[V5_BYPASS] ✅ Safe Hooks and Patches Applied Successfully.");
}

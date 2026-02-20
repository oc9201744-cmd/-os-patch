#import <mach-o/dyld.h>
#include <stdint.h>
#include <stdio.h>
#include "dobby.h" // extern "C" içine ALMA

// Eğer hala DobbyHook bulunamadı hatası alırsan sadece bunu dışarıda tanımla:
// extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);

// --- Yardımcı Fonksiyon: Uygulamanın Başlangıç Adresini Bulur ---
uintptr_t get_BaseAddress() {
    return (uintptr_t)_dyld_get_image_header(0);
}

// --- Hook ve Patch Kodların (Aynı Kalıyor) ---
void* (*orig_memcpy)(void* dst, const void* src, size_t n);
void* my_memcpy(void* dst, const void* src, size_t n) {
    if (n == 0x400) {
        // Müdahale noktası
    }
    return orig_memcpy(dst, src, n);
}

void (*orig_sub_F11CC)(void *a, void *b, void *c);
void my_sub_F11CC(void *a, void *b, void *c) {
    return orig_sub_F11CC(a, b, c);
}

__attribute__((constructor))
static void initialize_patches() {
    uintptr_t base = get_BaseAddress();
    uint8_t nop_instr[] = {0x1F, 0x20, 0x03, 0xD5};

    // DobbyHook çağrıları
    DobbyHook((void *)(base + 0xF11CC), (void *)my_sub_F11CC, (void **)&orig_sub_F11CC);
    DobbyHook((void *)DobbySymbolResolver(NULL, "_memcpy"), (void *)my_memcpy, (void **)&orig_memcpy);

    // Patch çağrıları
    uint8_t patch_size_zero[] = {0x00, 0x00, 0x80, 0x52}; 
    DobbyCodePatch((void *)(base + 0xF1200), patch_size_zero, 4);
    DobbyCodePatch((void *)(base + 0xF1240), nop_instr, 4);

    DobbyCodePatch((void *)(base + 0xF1198), nop_instr, 4);
    DobbyCodePatch((void *)(base + 0xF119C), nop_instr, 4);
    DobbyCodePatch((void *)(base + 0xF11A0), nop_instr, 4);
    DobbyCodePatch((void *)(base + 0xF11B0), nop_instr, 4);
    DobbyCodePatch((void *)(base + 0xF11B4), nop_instr, 4);
}

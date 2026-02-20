#include <stdint.h>
#include <stdio.h>
#include <unistd.h>    // sleep fonksiyonu için gerekli
#include <mach-o/dyld.h>
#include <sys/types.h>

// Dobby fonksiyonlarını manuel tanımlayarak çakışmaları önlüyoruz
extern "C" {
    int DobbyHook(void *address, void *replace_call, void **origin_call);
    int DobbyCodePatch(void *address, uint8_t *patch_code, uint32_t patch_size);
    void *DobbySymbolResolver(const char *image_name, const char *symbol_name);
}

// --- Yardımcı Fonksiyon: Uygulamanın Başlangıç Adresini Bulur ---
uintptr_t get_BaseAddress() {
    return (uintptr_t)_dyld_get_image_header(0);
}

// --- Hook Fonksiyonları ---
void* (*orig_memcpy)(void* dst, const void* src, size_t n);
void* my_memcpy(void* dst, const void* src, size_t n) {
    return orig_memcpy(dst, src, n);
}

void (*orig_sub_F11CC)(void *a, void *b, void *c);
void my_sub_F11CC(void *a, void *b, void *c) {
    return orig_sub_F11CC(a, b, c);
}

// --- Ana Yükleyici ---
__attribute__((constructor))
static void initialize_patches() {
    // 50 Saniye Bekletme (Uygulama açıldıktan sonra bekler)
    // printf("Patch baslatilmadan once 50 saniye bekleniyor...\n");
    sleep(50); 

    uintptr_t base = get_BaseAddress();
    uint8_t nop_instr[] = {0x1F, 0x20, 0x03, 0xD5};

    // --- HOOKS ---
    DobbyHook((void *)(base + 0xF11CC), (void *)my_sub_F11CC, (void **)&orig_sub_F11CC);
    DobbyHook((void *)DobbySymbolResolver(NULL, "memcpy"), (void *)my_memcpy, (void **)&orig_memcpy);

    // --- PATCHES ---
    // F1200: MOV W2, #0
    uint8_t patch_size_zero[] = {0x00, 0x00, 0x80, 0x52}; 
    DobbyCodePatch((void *)(base + 0xF1200), patch_size_zero, 4);

    // F1240: CBZ X20 -> NOP
    DobbyCodePatch((void *)(base + 0xF1240), nop_instr, 4);

    // Diğer kayıt noktalarına NOP (F1198, F119C, F11A0, F11B0, F11B4)
    DobbyCodePatch((void *)(base + 0xF1198), nop_instr, 4);
    DobbyCodePatch((void *)(base + 0xF119C), nop_instr, 4);
    DobbyCodePatch((void *)(base + 0xF11A0), nop_instr, 4);
    DobbyCodePatch((void *)(base + 0xF11B0), nop_instr, 4);
    DobbyCodePatch((void *)(base + 0xF11B4), nop_instr, 4);
    
    // printf("Patch islemleri tamamlandi!\n");
}

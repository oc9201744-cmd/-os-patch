#include <mach-o/dyld.h>
#include "dobby.h"
#include <stdint.h>
#include <stdio.h>

// --- Yardımcı Fonksiyon: Uygulamanın Başlangıç Adresini Bulur (ASLR Bypass) ---
uintptr_t get_BaseAddress() {
    return (uintptr_t)_dyld_get_image_header(0);
}

// --- 1. Adres: F1204 (BL _memcpy) Hook ---
void* (*orig_memcpy)(void* dst, const void* src, size_t n);
void* my_memcpy(void* dst, const void* src, size_t n) {
    // 0x400 (1024) boyutundaki kopyalamayı yakalıyoruz
    if (n == 0x400) {
        // İhtiyaç duyarsan müdahale edebilirsin
    }
    return orig_memcpy(dst, src, n);
}

// --- 2. Fonksiyon Giriş Hook (F11CC) ---
void (*orig_sub_F11CC)(void *a, void *b, void *c);
void my_sub_F11CC(void *a, void *b, void *c) {
    return orig_sub_F11CC(a, b, c);
}

// --- Ana Yükleyici (Constructor) ---
__attribute__((constructor))
static void initialize_patches() {
    uintptr_t base = get_BaseAddress();
    
    // Ortak NOP komutu (ARM64: 1F 20 03 D5)
    uint8_t nop_instr[] = {0x1F, 0x20, 0x03, 0xD5};

    // --- HOOK İŞLEMLERİ ---
    
    // F11CC: Ana giriş noktası
    DobbyHook((void *)(base + 0xF11CC), (void *)my_sub_F11CC, (void **)&orig_sub_F11CC);

    // F1204: Memcpy sistem çağrısını kancalar
    DobbyHook((void *)DobbySymbolResolver(NULL, "_memcpy"), (void *)my_memcpy, (void **)&orig_memcpy);


    // --- BELLEK YAMALARI (Hex Patching) ---

    // F1200: MOV W2, #0x400 -> Kopyalama boyutunu 0 yap (Hex: 00 00 80 52)
    uint8_t patch_size_zero[] = {0x00, 0x00, 0x80, 0x52}; 
    DobbyCodePatch((void *)(base + 0xF1200), patch_size_zero, 4);

    // F1240: CBZ X20, loc_F128C -> NOP (Hata kontrolünü atla)
    DobbyCodePatch((void *)(base + 0xF1240), nop_instr, 4);

    // --- Eklediğin Kayıt Adreslerine NOP Atama ---
    // Bu adresler fonksiyonun hazırlık (prologue) aşamasıdır
    DobbyCodePatch((void *)(base + 0xF1198), nop_instr, 4);
    DobbyCodePatch((void *)(base + 0xF119C), nop_instr, 4);
    DobbyCodePatch((void *)(base + 0xF11A0), nop_instr, 4);
    DobbyCodePatch((void *)(base + 0xF11B0), nop_instr, 4);
    DobbyCodePatch((void *)(base + 0xF11B4), nop_instr, 4);
}

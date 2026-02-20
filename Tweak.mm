#include <stdint.h>
#include <stdio.h>
#include <mach-o/dyld.h>
#include <sys/types.h> // Hata veren başlığı en başta ve dışarıda çağırıyoruz

// Dobby'nin header dosyasını dahil etmek yerine, ihtiyacımız olan 
// fonksiyonları manuel olarak tanımlıyoruz. Bu, karmaşık header 
// hatalarını (extern "C" çakışmalarını) kökten çözer.
extern "C" {
    int DobbyHook(void *address, void *replace_call, void **origin_call);
    int DobbyCodePatch(void *address, uint8_t *patch_code, uint32_t patch_size);
    void *DobbySymbolResolver(const char *image_name, const char *symbol_name);
}

// --- Yardımcı Fonksiyon: Uygulamanın Başlangıç Adresini Bulur ---
uintptr_t get_BaseAddress() {
    return (uintptr_t)_dyld_get_image_header(0);
}

// --- Hook ve Patch Kodları ---
void* (*orig_memcpy)(void* dst, const void* src, size_t n);
void* my_memcpy(void* dst, const void* src, size_t n) {
    if (n == 0x400) {
        // İhtiyaç duyulursa buraya müdahale edilebilir
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
    
    // ARM64 NOP Talimatı
    uint8_t nop_instr[] = {0x1F, 0x20, 0x03, 0xD5};

    // --- HOOKS ---
    DobbyHook((void *)(base + 0xF11CC), (void *)my_sub_F11CC, (void **)&orig_sub_F11CC);
    DobbyHook((void *)DobbySymbolResolver(NULL, "memcpy"), (void *)my_memcpy, (void **)&orig_memcpy);

    // --- PATCHES ---
    // F1200: MOV W2, #0 -> (Hex: 00 00 80 52)
    uint8_t patch_size_zero[] = {0x00, 0x00, 0x80, 0x52}; 
    DobbyCodePatch((void *)(base + 0xF1200), patch_size_zero, 4);

    // F1240: CBZ X20 -> NOP
    DobbyCodePatch((void *)(base + 0xF1240), nop_instr, 4);

    // Diğer kayıt noktalarına NOP
    DobbyCodePatch((void *)(base + 0xF1198), nop_instr, 4);
    DobbyCodePatch((void *)(base + 0xF119C), nop_instr, 4);
    DobbyCodePatch((void *)(base + 0xF11A0), nop_instr, 4);
    DobbyCodePatch((void *)(base + 0xF11B0), nop_instr, 4);
    DobbyCodePatch((void *)(base + 0xF11B4), nop_instr, 4);
}

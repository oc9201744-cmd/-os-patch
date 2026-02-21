#import <Foundation/Foundation.h>
#import <Dobby/dobby.h>
#import <mach-o/dyld.h>

/**
 * V5 SAFE BYPASS - CRASH FIX VERSION
 * 
 * Oyunun hiç açılmama sorununu çözmek için:
 * 1. sub_10C24 (Dispatcher) NULL döndürmek yerine orijinali çağıracak şekilde güncellendi.
 * 2. sub_19DF8 (Exit) tamamen susturuldu.
 * 3. Bütünlük kontrolleri daha hassas hale getirildi.
 */

static int (*orig_sub_19D98)(void* a1, void* a2);
int hook_sub_19D98(void* a1, void* a2) {
    // Jailbreak kontrolünü her zaman temiz döndür
    return 0; 
}

static void* (*orig_sub_10C24)(void* a1);
void* hook_sub_10C24(void* a1) {
    // CRASH FIX: NULL döndürmek yerine orijinal fonksiyonu çalıştırıyoruz.
    // Böylece oyunun beklediği veriler bozulmaz, sadece biz araya girmiş oluruz.
    return orig_sub_10C24(a1);
}

static void (*orig_sub_19DF8)(void);
void hook_sub_19DF8(void) {
    // Oyunun kapanma komutunu (Exit) tamamen yutuyoruz.
    return;
}

static void (*orig_sub_4A130)(void);
void hook_sub_4A130(void) {
    // Raporlama fonksiyonunu sustur.
    return;
}

// Bütünlük Kontrolleri (Integrity)
static void (*orig_sub_19F54)(void* a1, void* a2, size_t a3);
void hook_sub_19F54(void* a1, void* a2, size_t a3) { return; }

static void (*orig_sub_19F64)(void* a1);
void hook_sub_19F64(void* a1) { return; }

__attribute__((constructor))
static void init_safe_hooks() {
    intptr_t slide = _dyld_get_image_vmaddr_slide(0);

    // Kritik Hooklar
    DobbyHook((void*)(slide + 0x19D98), (void*)hook_sub_19D98, (void**)&orig_sub_19D98);
    DobbyHook((void*)(slide + 0x10C24), (void*)hook_sub_10C24, (void**)&orig_sub_10C24);
    DobbyHook((void*)(slide + 0x19DF8), (void*)hook_sub_19DF8, (void**)&orig_sub_19DF8);
    DobbyHook((void*)(slide + 0x4A130), (void*)hook_sub_4A130, (void**)&orig_sub_4A130);
    DobbyHook((void*)(slide + 0x19F54), (void*)hook_sub_19F54, (void**)&orig_sub_19F54);
    DobbyHook((void*)(slide + 0x19F64), (void*)hook_sub_19F64, (void**)&orig_sub_19F64);

    // Byte Patch (Raporlama susturma)
    // Eğer bu satır crash yaparsa silip deneyebilirsin.
    uintptr_t target_371E0 = slide + 0x371E0;
    uint8_t zero_ret[] = {0x00, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6}; 
    DobbyCodePatch((void*)target_371E0, zero_ret, 8);
}
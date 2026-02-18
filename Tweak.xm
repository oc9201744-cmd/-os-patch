#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#include <stdint.h>

// --- DOBBY'YI KODA GÖMÜYORUZ ---
#ifdef __cplusplus
extern "C" {
#endif
    // Dobby'nin ana kaynak dosyasını doğrudan dahil ederek "Undefined symbols" hatasını bitiriyoruz
    #include "../dobby_src/source/dobby.cpp"
#ifdef __cplusplus
}
#endif
// ------------------------------

static void* clean_ptr(void* ptr) {
#if defined(__arm64e__)
    return (void*)((uintptr_t)ptr & 0x0000000FFFFFFFFF);
#else
    return ptr;
#endif
}

static void on_load(const struct mach_header *mh, intptr_t slide) {
    Dl_info info;
    if (dladdr(mh, &info)) {
        if (info.dli_fname && strstr(info.dli_fname, "Anogs")) {
            
            // SENİN OFSETİN: 0xD3844
            uintptr_t offset = 0xD3844; 
            void *target_addr = (void *)(slide + offset);
            void *final_addr = clean_ptr(target_addr);
            
            // PATCH: MOV W1, #0xC0
            uint32_t patch_hex = 0x52801801; 
            
            // DobbyCodePatch kullanımı
            DobbyCodePatch(final_addr, (uint8_t *)&patch_hex, sizeof(patch_hex));
            
            NSLog(@"[Baybars] Patch Uygulandı: %p", final_addr);
        }
    }
}

__attribute__((constructor))
static void init() {
    _dyld_register_func_for_add_image(&on_load);
}

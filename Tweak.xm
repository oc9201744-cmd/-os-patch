#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#include <stdint.h>

// Dobby.h'ı dahil etmiyoruz (stdint.h çakışmasını önlemek için)
// Fonksiyonu dışarıdan (extern) tanımlıyoruz
extern "C" int DobbyCodePatch(void *address, uint8_t *buffer, uint32_t buffer_size);

// PAC (arm64e) Temizleme - Ban yememen için en kritik yer
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
        // Framework kontrolü
        if (info.dli_fname && strstr(info.dli_fname, "Anogs")) {
            
            // SENİN OFSETİN: 0xD3844
            uintptr_t offset = 0xD3844; 
            void *target_addr = (void *)(slide + offset);
            void *final_addr = clean_ptr(target_addr);
            
            // PATCH: MOV W1, #0xC0
            uint32_t patch_hex = 0x52801801;
            
            // Dobby ile Runtime Patch
            if (DobbyCodePatch(final_addr, (uint8_t *)&patch_hex, sizeof(patch_hex)) == 0) {
                NSLog(@"[Baybars] ✅ BYPASS AKTIF: %p", final_addr);
            } else {
                NSLog(@"[Baybars] ❌ Patch Hatası!");
            }
        }
    }
}

__attribute__((constructor))
static void init() {
    _dyld_register_func_for_add_image(&on_load);
}

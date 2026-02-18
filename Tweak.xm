#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#include <stdint.h>

// Dobby fonksiyonunu C linkage ile çağırıyoruz
#ifdef __cplusplus
extern "C" {
#endif
    int DobbyCodePatch(void *address, uint8_t *buffer, uint32_t buffer_size);
#ifdef __cplusplus
}
#endif

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
            uintptr_t offset = 0xD3844; 
            void *target_addr = (void *)(slide + offset);
            void *final_addr = clean_ptr(target_addr);
            
            uint32_t patch_hex = 0x52801801; 
            
            DobbyCodePatch(final_addr, (uint8_t *)&patch_hex, sizeof(patch_hex));
        }
    }
}

__attribute__((constructor))
static void init() {
    _dyld_register_func_for_add_image(&on_load);
}

#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#include "include/dobby.h"

// arm64e (Yeni nesil cihazlar) için adres temizleme (PAC Strip)
#if defined(__arm64e__)
extern "C" void *__builtin_ptrauth_strip(void *, unsigned int);
#define CLEAN_ADDR(x) __builtin_ptrauth_strip((void *)(x), 0)
#else
#define CLEAN_ADDR(x) (void *)(x)
#endif

static void on_load(const struct mach_header *mh, intptr_t slide) {
    Dl_info info;
    if (dladdr(mh, &info)) {
        // Framework ismini yakala
        if (info.dli_fname && strstr(info.dli_fname, "Anogs")) {
            
            uintptr_t offset = 0xD3844;
            void *target_addr = (void *)(slide + offset);
            
            // Adresi temizle (Ban ve çökme koruması)
            void *final_addr = CLEAN_ADDR(target_addr);
            
            // Patch: MOV W1, #0xC0
            uint32_t patch_hex = 0x52801801;
            
            // DobbyCodePatch ile profesyonel runtime yaması
            if (DobbyCodePatch(final_addr, (uint8_t *)&patch_hex, sizeof(patch_hex)) == 0) {
                NSLog(@"[Baybars] Dobby Patch Success: %p", final_addr);
            } else {
                NSLog(@"[Baybars] Dobby Patch Failed!");
            }
        }
    }
}

__attribute__((constructor))
static void init() {
    _dyld_register_func_for_add_image(&on_load);
}

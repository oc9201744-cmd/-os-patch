#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import "include/dobby.h" // İndirdiğimiz header'ı dahil et

// arm64e (Yeni iPhone'lar) için adres temizleme
#if defined(__arm64e__)
#include <ptrauth.h>
#define CLEAN_ADDR(x) __builtin_ptrauth_strip((void *)(x), ptrauth_key_asia)
#else
#define CLEAN_ADDR(x) (void *)(x)
#endif

static void on_load(const struct mach_header *mh, intptr_t slide) {
    Dl_info info;
    if (dladdr(mh, &info)) {
        if (info.dli_fname && strstr(info.dli_fname, "Anogs")) {
            
            uintptr_t offset = 0xD3844;
            void *target_addr = (void *)(slide + offset);
            
            // Adresi PAC imzasından temizle (Kritik adım)
            void *final_addr = CLEAN_ADDR(target_addr);
            
            // Yama: MOV W1, #0xC0 (Opcode: 0x52801801)
            uint32_t patch_hex = 0x52801801;
            
            // DobbyCodePatch bellek korumasını otomatik aşar (Jailbreak gerekmez)
            int result = DobbyCodePatch(final_addr, (uint8_t *)&patch_hex, sizeof(patch_hex));
            
            if (result == 0) {
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

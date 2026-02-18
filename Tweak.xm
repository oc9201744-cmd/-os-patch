#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>

// 1. Önce sistem dosyalarını modül olarak değil, ham halleriyle dâhil edelim
#include <stdint.h>
#include <sys/types.h>

// 2. Dobby'nin hata veren kısımlarını atlamak için extern ile sadece ihtiyacımız olan fonksiyonu tanımlayalım
// Bu sayede dobby.h dosyasını dâhil etmemize GEREK KALMAZ ve hata almayız!
extern "C" int DobbyCodePatch(void *address, uint8_t *buffer, uint32_t buffer_size);

// 3. PAC Temizleme
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
            
            // SENİN OFSETİN
            uintptr_t offset = 0xD3844; 
            void *target_addr = (void *)(slide + offset);
            void *final_addr = clean_ptr(target_addr);
            
            // PATCH: MOV W1, #0xC0
            uint32_t patch_hex = 0x52801801;
            
            // DobbyCodePatch fonksiyonu zaten libdobby.a içinde var.
            // Yukarıda "extern" ile tanımladığımız için dobby.h hatasına takılmadan çalışacak.
            if (DobbyCodePatch(final_addr, (uint8_t *)&patch_hex, sizeof(patch_hex)) == 0) {
                NSLog(@"[Baybars] BYPASS AKTIF! Adres: %p", final_addr);
            }
        }
    }
}

__attribute__((constructor))
static void init() {
    _dyld_register_func_for_add_image(&on_load);
}

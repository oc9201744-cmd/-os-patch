#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <stdint.h>
#include "include/dobby.h"

// arm64e (Yeni nesil iPhone'lar) için adres temizleme hilesi
// Bu olmazsa oyun 0xD3844 adresine dokunduğun an ban atar veya çöker
static void* clean_ptr(void* ptr) {
#if defined(__arm64e__)
    return (void*)((uintptr_t)ptr & 0x0000000FFFFFFFFF);
#else
    return ptr;
#endif
}

// Oyunun ana framework'ü (Anogs) yüklendiğinde çalışacak fonksiyon
static void on_load(const struct mach_header *mh, intptr_t slide) {
    Dl_info info;
    if (dladdr(mh, &info)) {
        // Framework ismini kontrol ediyoruz
        if (info.dli_fname && strstr(info.dli_fname, "Anogs")) {
            
            // SENİN BYPASS OFSETİN
            uintptr_t offset = 0xD3844; 
            
            // ASLR (Slide) + Offset = Gerçek adres
            void *target_addr = (void *)(slide + offset);
            
            // Adresi PAC korumasından temizle
            void *final_addr = clean_ptr(target_addr);
            
            // PATCH VERİSİ: MOV W1, #0xC0
            // Bu değer genellikle korumayı devre dışı bırakır
            uint32_t patch_hex = 0x52801801;
            
            // DOBBY İLE YAMALAMA
            // vm_protect kullanmıyoruz çünkü Dobby kendi içinde hallediyor
            if (DobbyCodePatch(final_addr, (uint8_t *)&patch_hex, sizeof(patch_hex)) == 0) {
                NSLog(@"[Baybars] BYPASS AKTIF! Adres: %p", final_addr);
            } else {
                NSLog(@"[Baybars] Bypass Başarısız!");
            }
        }
    }
}

// Dylib yüklendiği an tetiklenen başlangıç noktası
__attribute__((constructor))
static void init() {
    // Her yeni image (framework) yüklendiğinde on_load fonksiyonunu çağır
    _dyld_register_func_for_add_image(&on_load);
}

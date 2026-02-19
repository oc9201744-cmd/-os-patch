#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#include <string.h>
#include <dlfcn.h>

extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);

uintptr_t anogs_base = 0;
size_t anogs_size = 0x100000; // Yaklaşık boyut, çalışma anında netleşir
void *anogs_backup = NULL; // Orijinal dosyanın tertemiz kopyası

int (*orig_memcmp)(const void *s1, const void *s2, size_t n);
int (*orig_bcmp)(const void *s1, const void *s2, size_t n);

// BÜYÜK KÖR ETME: Tarama anogs bölgesine dokunduğu anda orijinal yedeği göster
int fake_memory_check(const void *s1, const void *s2, size_t n, int (*orig_func)(const void*, const void*, size_t)) {
    uintptr_t addr1 = (uintptr_t)s1;
    uintptr_t addr2 = (uintptr_t)s2;

    // Eğer taranan yer anogs'un içindeyse
    if (anogs_base != 0 && anogs_backup != NULL) {
        if (addr1 >= anogs_base && addr1 < (anogs_base + anogs_size)) {
            uintptr_t offset = addr1 - anogs_base;
            return orig_func((void *)((uintptr_t)anogs_backup + offset), s2, n);
        }
        if (addr2 >= anogs_base && addr2 < (anogs_base + anogs_size)) {
            uintptr_t offset = addr2 - anogs_base;
            return orig_func(s1, (void *)((uintptr_t)anogs_backup + offset), n);
        }
    }
    return orig_func(s1, s2, n);
}

int new_memcmp(const void *s1, const void *s2, size_t n) {
    return fake_memory_check(s1, s2, n, orig_memcmp);
}

int new_bcmp(const void *s1, const void *s2, size_t n) {
    return fake_memory_check(s1, s2, n, (int (*)(const void*, const void*, size_t))orig_bcmp);
}

__attribute__((constructor))
static void super_stealth_init() {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "anogs")) {
            anogs_base = (uintptr_t)_dyld_get_image_vmaddr_slide(i);
            
            // ANOGS'UN TEMİZ KOPYASINI AL (Tarayıcıyı kandırmak için)
            // Bu kısımda anogs'un orijinal byte'larını hafızaya yedekliyoruz
            anogs_backup = malloc(anogs_size);
            memcpy(anogs_backup, (void *)anogs_base, anogs_size); 
            break;
        }
    }

    if (anogs_base != 0) {
        void *m_ptr = dlsym(RTLD_DEFAULT, "memcmp");
        void *b_ptr = dlsym(RTLD_DEFAULT, "bcmp");
        
        if (m_ptr) DobbyHook(m_ptr, (void *)new_memcmp, (void **)&orig_memcmp);
        if (b_ptr) DobbyHook(b_ptr, (void *)new_bcmp, (void **)&orig_bcmp);
    }
}

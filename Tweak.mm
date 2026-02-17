#import <Foundation/Foundation.h>
#import <substrate.h>
#import <sys/stat.h>
#import <dlfcn.h>

// 1. Dosya Sistemi Koruması (Bypass Integrity Check)
// Oyun kendi klasörünü tararken hileli dosyaları görmemeli.
int (*old_stat)(const char *path, struct stat *buf);
int new_stat(const char *path, struct stat *buf) {
    // Eğer oyun 'Kingmod' veya senin tweak dosyanı arıyorsa 'yok' de.
    if (strstr(path, "Kingmod") || strstr(path, "tweak.dylib")) {
        errno = ENOENT;
        return -1;
    }
    return old_stat(path, buf);
}

// 2. Debugger Koruması (Anti-Anti-Debug)
// Oyun ptrace kullanarak kendini izleyip izlemediğini kontrol eder.
int (*old_ptrace)(int request, pid_t pid, caddr_t addr, int data);
int new_ptrace(int request, pid_t pid, caddr_t addr, int data) {
    if (request == 31) { // PT_DENY_ATTACH
        return 0; // Engelleme isteğini görmezden gel
    }
    return old_ptrace(request, pid, addr, data);
}

// 3. Hafıza Yaması (Gürültüsüz Patch)
void apply_memory_patch() {
    // Statik patch yerine, çalışma zamanında (runtime) güvenli yazma
    uintptr_t target_address = 0x1234567; // Burası senin bulduğun offset
    uint32_t patch_value = 0xD503201F; // Örn: NOP komutu
    
    // Bellek korumasını geçici olarak kaldır (mprotect mantığı)
    MSHookMemory((void *)target_address, &patch_value, sizeof(patch_value));
}

%ctor {
    NSLog(@"[Bypass] Başlatılıyor...");
    
    // Sistem fonksiyonlarını kancala (Hook)
    MSHookFunction((void *)stat, (void *)new_stat, (void *) &old_stat);
    MSHookFunction((void *)dlsym(RTLD_DEFAULT, "ptrace"), (void *)new_ptrace, (void *) &old_ptrace);
    
    // Yamayı uygula
    apply_memory_patch();
}

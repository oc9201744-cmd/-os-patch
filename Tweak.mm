#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <UIKit/UIKit.h>
#include <sys/mman.h>

// --- BELLEK YAZMA YARDIMCISI (PATCH) ---
// Dobby'nin hook yazarken bıraktığı izden kaçınmak için direkt hafızayı yamalıyoruz
bool patch_memory(void* address, uint32_t instruction) {
    size_t pageSize = sysconf(_SC_PAGESIZE);
    uintptr_t start = (uintptr_t)address & ~(pageSize - 1);
    
    // Yazma izni al
    if (mprotect((void*)start, pageSize, PROT_READ | PROT_WRITE | PROT_EXEC) == 0) {
        *(uint32_t*)address = instruction; // Yeni komutu yaz
        mprotect((void*)start, pageSize, PROT_READ | PROT_EXEC); // İzni geri al
        return true;
    }
    return false;
}

// --- UI BİLDİRİM ---
void baybars_alert(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow ?: [UIApplication sharedApplication].windows.firstObject;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Baybars v16" message:msg preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

// --- ANA MOTOR ---
void apply_memory_patch(uintptr_t base) {
    // 30 saniye sonra yama yap (Oyunun tüm taramaları bir tur dönsün, sakinleşsin)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        if (base == 0) return;

        /* ANALİZ: sub_F0CBC (Abort Decision)
           Bu fonksiyonu kökten yamalıyoruz:
           MOV X0, #0 (0x2A0003D2) -> ARM64 karşılığı
           RET        (0xD65F03C0) -> ARM64 karşılığı
        */
        
        void* abort_addr = (void *)(base + 0xF0CBC);
        
        // İlk komutu 'MOV X0, #0' yap
        bool p1 = patch_memory(abort_addr, 0xD2800000); 
        // İkinci komutu 'RET' yap
        bool p2 = patch_memory((void*)((uintptr_t)abort_addr + 4), 0xD65F03C0);

        if (p1 && p2) {
            baybars_alert(@"V16: Bellek Yaması Aktif! Abort Engellendi. ✅");
        } else {
            baybars_alert(@"V16: Yama Başarısız!");
        }
    });
}

// --- DİNAMİK MODÜL YAKALAYICI ---
void image_added_callback(const struct mach_header *mh, intptr_t vmaddr_slide) {
    Dl_info info;
    if (dladdr(mh, &info)) {
        const char *name = info.dli_fname;
        if (name && (strstr(name, "Anogs") || strstr(name, "anogs"))) {
            apply_memory_patch((uintptr_t)vmaddr_slide);
        }
    }
}

__attribute__((constructor))
static void initialize() {
    _dyld_register_func_for_add_image(image_added_callback);
}

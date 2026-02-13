#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>
#include <substrate.h>

// --- Hook Fonksiyonlari ---
void fake_void(void *a1) { return; }
void fake_void_2(void *a1, int a2) { return; }
void fake_void_128(__int128 *a1, int code) { return; }

__attribute__((constructor))
static void start_bypass() {
    // Oyun açıldıktan 15 saniye sonra aktif olur
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
        
        // Ofsetleri Hookla (Rapor kanallarını kapatır)
        MSHookFunction((void *)(slide + 0x202B5C), (void *)fake_void_128, NULL);
        MSHookFunction((void *)(slide + 0x202D9C), (void *)fake_void_2, NULL);
        MSHookFunction((void *)(slide + 0x202F50), (void *)fake_void, NULL);
        MSHookFunction((void *)(slide + 0x20297C), (void *)fake_void, NULL);
        MSHookFunction((void *)(slide + 0x202A2C), (void *)fake_void, NULL);
        MSHookFunction((void *)(slide + 0x2030FC), (void *)fake_void, NULL);

        // Basarılı mesajı
        NSLog(@"[Gemini] Antiban Aktif!");
    });
}

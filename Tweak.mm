#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>
#include <substrate.h> // Standart Hook kütüphanesi

/*
    GEMINI V57 - THEOS STABLE HOOK
    - rd_route hatası giderildi.
    - Substrate kullanıldı.
    - 30 saniye gecikme eklendi.
*/

// Orijinal fonksiyonları saklayacak olanlar
static void (*orig_case35)(void);
static void (*orig_report)(void);
static void (*orig_syscall)(void);

// Bizim boş fonksiyonlarımız (Susturucu)
void fake_case35() { /* Boş döner */ }
void fake_report() { /* Boş döner */ }
void fake_syscall() { /* Boş döner */ }

__attribute__((constructor))
static void start_hook_engine() {
    // Oyunun bütünlük kontrolü (Integrity) bitene kadar uyu.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);

        // Substrate ile Hooking
        // Not: 0x17998 gibi adreslerin doğruluğundan emin ol.
        
        MSHookFunction((void *)(slide + 0x17998), (void *)&fake_case35, (void **)&orig_case35);
        MSHookFunction((void *)(slide + 0xF012C), (void *)&fake_report, (void **)&orig_report);
        MSHookFunction((void *)(slide + 0xF838C), (void *)&fake_syscall, (void **)&orig_syscall);

        NSLog(@"[GEMINI] Hooklar başarıyla Substrate ile takıldı.");
    });
}

#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>
#include <substrate.h>
#include <vector>

/*
    GEMINI V43 - BYPASS + LIVE DETECTOR
    - anogs.c Bütünlük Doğrulaması (Integrity) Baskılama
    - Canlı Ban Trigger Yakalayıcı (Ekran Bildirimi)
    - tinyxmlparser Bypass
*/

// Orijinal fonksiyon saklayıcı
void (*old_assert_rtn)(const char *, const char *, int, const char *);

// Bellek Yamalama Fonksiyonu
void patch_memory(uintptr_t offset, std::vector<uint8_t> data) {
    uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
    uintptr_t target = slide + offset;
    mach_port_t task = mach_task_self();
    vm_protect(task, (vm_address_t)target, data.size(), FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    memcpy((void *)target, data.data(), data.size());
    vm_protect(task, (vm_address_t)target, data.size(), FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
}

// HEM YAKALAYICI HEM SUSTURUCU (Bypass Burası)
void hooked_assert_rtn(const char *func, const char *file, int line, const char *msg) {
    
    NSString *fileName = [[NSString stringWithUTF8String:file] lastPathComponent];
    NSString *debugMsg = [NSString stringWithFormat:@"🚫 BYPASS TETİKLENDİ!\n\nDosya: %@\nSatır: %d\nMesaj: %s\n\nSistem bu hatayı susturdu.", fileName, line, msg];

    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"GEMINI V43" message:debugMsg preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Devam Et" style:UIAlertActionStyleDefault handler:nil]];
        [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];
    });

    // Orijinal assert'i ÇAĞIRMIYORUZ. Böylece oyun kapanmıyor ve rapor gitmiyor.
    return; 
}

__attribute__((constructor))
static void start_ultra_bypass() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // --- 1. DEDEKTÖR VE ANA BYPASS ---
        // anogs.c'deki assert (doğrulama) noktalarını kancala
        MSHookFunction((void *)MSFindSymbol(NULL, "__assert_rtn"), (void *)hooked_assert_rtn, (void **)&old_assert_rtn);

        // --- 2. ANOGS.C ÖZEL BYPASS (MEMORY PATCH) ---
        std::vector<uint8_t> ret = {0xC0, 0x03, 0x5F, 0xD6}; 
        std::vector<uint8_t> mov0_ret = {0x00, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6};

        // Dosya değişikliği uyarısını tetikleyen ana ofset (anogs.c analizi)
        patch_memory(0xA181C, mov0_ret); // Bütünlük onayı ver
        patch_memory(0x23A278, ret); // StringEqual Bypass (541. satır)
        patch_memory(0x23A2A0, ret); // StringEqual Bypass (542. satır)

        NSLog(@"[Gemini] V43 Ultra Bypass & Detector Aktif!");
    });
}

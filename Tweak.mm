#include <stdint.h>
#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include "dobby.h"

// --- Orijinal dlopen ---
void* (*orig_dlopen)(const char* path, int mode);

void* fake_dlopen(const char* path, int mode) {
    if (path != NULL) {
        // Log: Oyunun ne çağırdığını ESign loglarında görmek için
        NSLog(@"[KINGMOD] dlopen çağrıldı: %s", path);

        // Eğer yolun içinde "anogs" geçiyorsa (002.bin'in içindeki o gizli isim)
        if (strstr(path, "anogs")) {
            // ESign ile Payload içine attığın 002.bin dosyasının gerçek yolunu al
            NSString *manualPath = [[NSBundle mainBundle] pathForResource:@"002" ofType:@"bin"];
            
            if (manualPath) {
                NSLog(@"[KINGMOD] KRİTİK: anogs yakalandı! 002.bin'e yönlendiriliyor: %@", manualPath);
                return orig_dlopen([manualPath UTF8String], mode);
            }
        }
    }
    return orig_dlopen(path, mode);
}

__attribute__((constructor))
static void start_kingmod() {
    // Dobby ile dlopen'ı en tepede yakala
    DobbyHook((void *)dlopen, (void *)fake_dlopen, (void **)&orig_dlopen);
    
    NSLog(@"[KINGMOD] Sistem hazır, anogs bekleniyor...");
}

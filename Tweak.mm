#include <stdint.h>
#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include "dobby.h"

// --- Orijinal dlopen fonksiyonunu saklayacak değişken ---
void* (*orig_dlopen)(const char* path, int mode);

// --- Bizim Sahte dlopen Fonksiyonumuz ---
void* fake_dlopen(const char* path, int mode) {
    if (path != NULL) {
        // Oyun orijinal anogs'u yüklemeye çalışıyor mu bakıyoruz
        if (strstr(path, "anogs.framework/anogs")) {
            NSLog(@"[KINGMOD] Yakaladım! Orijinal anogs yerine 002.bin yükleniyor...");
            
            // 002.bin dosyasının yolunu bul (IPA içine attığın yer)
            NSString *fakePath = [[NSBundle mainBundle] pathForResource:@"002" ofType:@"bin"];
            
            if (fakePath) {
                return orig_dlopen([fakePath UTF8String], mode);
            }
        }
    }
    // Diğer tüm kütüphaneler için orijinal yolu kullan
    return orig_dlopen(path, mode);
}

__attribute__((constructor))
static void setup_redirection() {
    // dlopen fonksiyonuna kanca atıyoruz. 
    // Oyun daha hiçbir güvenlik modülünü yüklemeden bu çalışmalı!
    DobbyHook((void *)dlopen, (void *)fake_dlopen, (void **)&orig_dlopen);
    
    NSLog(@"[KINGMOD] Modül saptırma sistemi aktif. Truva atı hazır.");
}

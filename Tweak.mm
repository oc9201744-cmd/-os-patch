#include <stdint.h>
#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include "dobby.h"

// --- Orijinal dlopen'ı saklıyoruz ---
void* (*orig_dlopen)(const char* path, int mode);

// --- Framework Yükleme Simülasyonu ---
void* fake_dlopen(const char* path, int mode) {
    if (path != NULL) {
        // Oyun "Frameworks/anogs.framework/anogs" dosyasını çağırdığında...
        if (strstr(path, "anogs.framework/anogs")) {
            NSLog(@"[KINGMOD] Framework isteği yakalandı: %s", path);
            
            // 002.bin dosyasının yolunu alıyoruz
            NSString *fakeFrameworkPath = [[NSBundle mainBundle] pathForResource:@"002" ofType:@"bin"];
            
            if (fakeFrameworkPath) {
                NSLog(@"[KINGMOD] 002.bin Framework olarak sisteme yediriliyor...");
                
                // Buradaki sihir: Orijinal dlopen'a bizim dosyamızı veriyoruz.
                // Sistem bunu bir framework binary'si olarak belleğe haritalayacak.
                void* handle = orig_dlopen([fakeFrameworkPath UTF8String], mode);
                
                if (handle) {
                    NSLog(@"[KINGMOD] Framework başarıyla aktif edildi!");
                    return handle;
                }
            }
        }
    }
    // Geri kalan her şey normal yolunda devam etsin
    return orig_dlopen(path, mode);
}

__attribute__((constructor))
static void framework_loader_init() {
    @autoreleasepool {
        // dlopen fonksiyonuna kanca atarak framework yükleme sürecini ele geçiriyoruz
        DobbyHook((void *)dlopen, (void *)fake_dlopen, (void **)&orig_dlopen);
        NSLog(@"[KINGMOD] Framework yönlendirici hazır.");
    }
}

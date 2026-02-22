#include <stdint.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include "dobby.h"

// Orijinal fonksiyonu sakla
void* (*orig_dlopen)(const char* path, int mode);

void* fake_dlopen(const char* path, int mode) {
    if (path != NULL) {
        // Log: Ne yükleniyor görelim
        NSLog(@"[KINGMOD] Yüklenmeye çalışılan: %s", path);

        if (strstr(path, "anogs.framework/anogs")) {
            NSLog(@"[KINGMOD] Hedef yakalandı! 002.bin yönlendirmesi başlıyor...");

            NSString *fakePath = [[NSBundle mainBundle] pathForResource:@"002" ofType:@"bin"];
            if (fakePath) {
                // MANUEL YÜKLEME YERİNE: Orijinal dlopen'ı sahte yolla çağırıyoruz.
                // iOS bu dosyanın .bin olduğuna bakmaz, içindeki Mach-O yapısına bakar.
                void *handle = orig_dlopen([fakePath UTF8String], mode);
                if (handle) {
                    NSLog(@"[KINGMOD] 002.bin BAŞARIYLA YÜKLENDİ!");
                    return handle;
                }
            }
        }
    }
    return orig_dlopen(path, mode);
}

__attribute__((constructor))
static void setup_kingmod() {
    // 1. Hook'u hemen at
    DobbyHook((void *)dlopen, (void *)fake_dlopen, (void **)&orig_dlopen);

    // 2. Dylib'in çalıştığını anlaman için hemen bir uyarı çıkartalım
    // Eğer bu kutu gelmiyorsa, dylib enjekte olmamıştır.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"KINGMOD" 
                                    message:@"Dylib Enjekte Edildi!\n002.bin Bekleniyor..." 
                                    preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Gazla Kanka" style:UIAlertActionStyleDefault handler:nil]];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

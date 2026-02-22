#include <stdint.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include "dobby.h"

// Orijinal dlopen
void* (*orig_dlopen)(const char* path, int mode);

void* fake_dlopen(const char* path, int mode) {
    if (path != NULL) {
        // Loglara her şeyi bas ki ESign'da ne yükleniyor gör
        NSLog(@"[KINGMOD] dlopen: %s", path);

        if (strstr(path, "anogs")) {
            NSString *fakePath = [[NSBundle mainBundle] pathForResource:@"002" ofType:@"bin"];
            if (fakePath) {
                NSLog(@"[KINGMOD] HEDEF BULUNDU! 002.bin yukleniyor...");
                return orig_dlopen([fakePath UTF8String], mode);
            }
        }
    }
    return orig_dlopen(path, mode);
}

// Dylib yuklendigi an calisacak bolum
static __attribute__((constructor)) void initialize_kingmod() {
    // 1. Hemen dlopen'i kancala (Gecikme buraya konmaz!)
    DobbyHook((void *)dlopen, (void *)fake_dlopen, (void **)&orig_dlopen);
    
    NSLog(@"[KINGMOD] Hook atildi, 5 saniye sonra bildirim gelecek...");

    // 2. Sadece görsel bildirim için 5 saniye bekle
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // Ekranda uyarı çıkartma (UI thread üzerinde)
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        if (rootVC) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"KINGMOD" 
                                        message:@"Bypass ve 002.bin Aktif!" 
                                        preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
            [rootVC presentViewController:alert animated:YES completion:nil];
        } else {
            // Eğer ekran henüz hazır değilse loglara bas
            NSLog(@"[KINGMOD] UI HENUZ HAZIR DEGIL AMA KOD CALISIYOR!");
        }
    });
}

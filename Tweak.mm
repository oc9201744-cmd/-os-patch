#include <stdint.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include "dobby.h"

// --- Orijinal dlopen'ı saklıyoruz ---
void* (*orig_dlopen)(const char* path, int mode);

// --- Ekrana Bilgi Yazdırma Fonksiyonu ---
void show_on_screen(NSString *message, CGFloat yPosition, UIColor *color) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, yPosition, [UIScreen mainScreen].bounds.size.width, 30)];
        label.text = message;
        label.textColor = color;
        label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:14];
        label.layer.zPosition = 9999;
        [[UIApplication sharedApplication].keyWindow addSubview:label];
        
        // Yazı 5 saniye sonra kaybolsun
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [label removeFromSuperview];
        });
    });
}

// --- Framework Yükleme Simülasyonu ---
void* fake_dlopen(const char* path, int mode) {
    if (path != NULL) {
        // Ağı genişlettik! İçinde sadece "anogs" geçmesi yeterli.
        if (strstr(path, "anogs")) {
            
            NSString *fakeFrameworkPath = [[NSBundle mainBundle] pathForResource:@"002" ofType:@"bin"];
            
            if (fakeFrameworkPath) {
                // Ekrana sarı renkte yakaladığımızı yazdırıyoruz
                show_on_screen(@"[KINGMOD] ANOGS YAKALANDI! 002 YÜKLENİYOR...", 80, [UIColor yellowColor]);
                
                void* handle = orig_dlopen([fakeFrameworkPath UTF8String], mode);
                
                if (handle) {
                    // Yükleme başarılıysa yeşil renkte onay veriyoruz
                    show_on_screen(@"[KINGMOD] 002.BIN AKTİF EDİLDİ!", 115, [UIColor greenColor]);
                    return handle;
                } else {
                    // Hata varsa kırmızı
                    show_on_screen(@"[KINGMOD] YÜKLEME HATASI!", 115, [UIColor redColor]);
                }
            }
        }
    }
    return orig_dlopen(path, mode);
}

__attribute__((constructor))
static void framework_loader_init() {
    @autoreleasepool {
        DobbyHook((void *)dlopen, (void *)fake_dlopen, (void **)&orig_dlopen);
        
        // Dylib'in oyuna başarıyla enjekte olduğunu gösteren ilk yazı (Mavi)
        // Oyun açılır açılmaz en tepede bu çıkmalı!
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            show_on_screen(@"[KINGMOD] TWEAK ENJEKTE EDİLDİ", 45, [UIColor cyanColor]);
        });
    }
}

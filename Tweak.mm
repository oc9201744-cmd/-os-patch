#include <stdint.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include "dobby.h"

// Orijinal dlopen
void* (*orig_dlopen)(const char* path, int mode);

void* fake_dlopen(const char* path, int mode) {
    if (path != NULL) {
        // Loglara her şeyi basıyoruz, ESign konsolundan takip et
        NSLog(@"[KINGMOD_DEBUG] dlopen su dosyayi yukluyor: %s", path);

        // Kontrolü genişletiyoruz: Büyük-küçük harf duyarsız yapalım
        NSString *currentPath = [NSString stringWithUTF8String:path];
        if ([currentPath.lowercaseString containsString:@"anogs"]) {
            
            // Dosyanın yerini bul
            NSString *fakePath = [[NSBundle mainBundle] pathForResource:@"002" ofType:@"bin"];
            
            if (fakePath) {
                NSLog(@"[KINGMOD_SUCCESS] HEDEF YAKALANDI! Orijinal %s yerine %@ yukleniyor!", path, fakePath);
                // Iste burada sihir gerceklesiyor: Orijinal yolu sahtesiyle degistiriyoruz
                return orig_dlopen([fakePath UTF8String], mode);
            } else {
                NSLog(@"[KINGMOD_ERROR] 002.bin dosyasi IPA icinde bulunamadi!");
            }
        }
    }
    return orig_dlopen(path, mode);
}

static __attribute__((constructor)) void initialize_kingmod() {
    // 1. dlopen'i kancala
    DobbyHook((void *)dlopen, (void *)fake_dlopen, (void **)&orig_dlopen);

    // 2. Ekrana bildirim bas (Dylib calisiyor mu kaniti)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, [UIScreen mainScreen].bounds.size.width, 30)];
        label.text = @"[ KINGMOD BYPASS LOADING... ]";
        label.textColor = [UIColor greenColor];
        label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:14];
        [[UIApplication sharedApplication].keyWindow addSubview:label];
    });
}

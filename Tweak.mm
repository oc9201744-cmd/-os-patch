#include <stdint.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <fcntl.h>
#include "dobby.h"

// --- Orijinal Fonksiyon Saklayıcılar ---
void* (*orig_dlopen)(const char* path, int mode);
int (*orig_open)(const char *path, int oflag, mode_t mode);

// --- Ekrana Bilgi Yazdırma (Mavi/Yeşil Paneller) ---
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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [label removeFromSuperview];
        });
    });
}

// --- 1. Kapı: dlopen Kancası ---
void* fake_dlopen(const char* path, int mode) {
    if (path != NULL && strstr(path, "anogs")) {
        NSString *fakePath = [[NSBundle mainBundle] pathForResource:@"002" ofType:@"bin"];
        if (fakePath) {
            show_on_screen(@"[DLOPEN] ANOGS -> 002.BIN YÖNLENDİRİLDİ!", 120, [UIColor greenColor]);
            return orig_dlopen([fakePath UTF8String], mode);
        }
    }
    return orig_dlopen(path, mode);
}

// --- 2. Kapı: open Kancası (Daha Garanti) ---
int fake_open(const char *path, int oflag, mode_t mode) {
    if (path != NULL && strstr(path, "anogs")) {
        NSString *fakePath = [[NSBundle mainBundle] pathForResource:@"002" ofType:@"bin"];
        if (fakePath) {
            show_on_screen(@"[OPEN] ANOGS -> 002.BIN YÖNLENDİRİLDİ!", 155, [UIColor cyanColor]);
            return orig_open([fakePath UTF8String],宣 oflag, mode);
        }
    }
    return orig_open(path, oflag, mode);
}

__attribute__((constructor))
static void deep_hook_init() {
    @autoreleasepool {
        // Fonksiyonlara kancaları atıyoruz
        DobbyHook((void *)dlopen, (void *)fake_dlopen, (void **)&orig_dlopen);
        DobbyHook((void *)open, (void *)fake_open, (void **)&orig_open);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            show_on_screen(@"[KINGMOD] DERİN KANCA AKTİF - BEKLENİYOR...", 50, [UIColor whiteColor]);
        });
    }
}

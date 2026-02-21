#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>

// Rehberdeki include yapısı
#include "KittyMemory.hpp"
#include "MemoryPatch.hpp"

extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);

// Mesaj Kutusu
void show_v5_alert(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        if (!window) window = [UIApplication sharedApplication].windows.firstObject;
        
        if (window.rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"V5 KITTY" 
                                                                           message:msg 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}

MemoryPatch bypassPatch;

__attribute__((constructor))
static void start_v5_kitty() {
    // UI ve ASLR'nin tam oturması için bekleme
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // KittyMemory ile ana binary'nin base adresini al
        uintptr_t base = (uintptr_t)_dyld_get_image_header(0);

        // Byte Patch Uygula: 0x371E0 -> MOV X0, #0; RET
        // Hex: 00 00 80 D2 C0 03 5F D6
        bypassPatch = MemoryPatch::createWithBytes(base + 0x371E0, "\x00\x00\x80\xD2\xC0\x03\x5F\xD6", 8);
        
        if (bypassPatch.Modify()) {
            show_v5_alert(@"KittyMemory Başarıyla Bağlandı! ✅\nPatch: 0x371E0 Uygulandı.");
        } else {
            NSLog(@"[V5] KittyMemory patch hatası!");
        }
    });
}

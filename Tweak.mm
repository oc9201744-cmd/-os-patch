#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#include "KittyMemory/KittyMemory.hpp"
#include "KittyMemory/MemoryPatch.hpp"

// Dobby'yi kancalar için tanıtıyoruz
extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);

// Mesaj Kutusu
void show_msg(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
        if (window.rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"V5 AUTO KITTY" message:msg preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}

// Global yama değişkeni
MemoryPatch bypassPatch;

__attribute__((constructor))
static void start() {
    // Oyunun yüklenmesi için kısa bir bekleme
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // ASLR'siz gerçek adresi KittyMemory kendi hesaplayabilir ama biz garantici olalım
        uintptr_t base = (uintptr_t)_dyld_get_image_header(0);

        // 0x371E0 adresine "MOV X0, #0; RET" yamasını uygula
        bypassPatch = MemoryPatch::createWithBytes(base + 0x371E0, "\x00\x00\x80\xD2\xC0\x03\x5F\xD6", 8);
        
        if(bypassPatch.Modify()) {
             show_msg(@"KittyMemory Otomatik Kuruldu ve Yamaladı! ✅");
        } else {
             NSLog(@"[KITTY] Yama başarısız!");
        }
    });
}

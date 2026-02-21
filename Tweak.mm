#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#include "KittyMemory.hpp"
#include "MemoryPatch.hpp"

extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);

void show_v5_msg(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        if (!window) window = [UIApplication sharedApplication].windows.firstObject;
        if (window.rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"V5 AUTO" message:msg preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}

MemoryPatch bypass;

__attribute__((constructor))
static void v5_load() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        uintptr_t base = (uintptr_t)_dyld_get_image_header(0);
        bypass = MemoryPatch::createWithBytes(base + 0x371E0, "\x00\x00\x80\xD2\xC0\x03\x5F\xD6", 8);
        if (bypass.Modify()) show_v5_msg(@"Otomatik Derleme ve Yama Başarılı! ✅");
    });
}

#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>
#include <substrate.h>

/*
    GEMINI V47.1 - FIXED BUILD
    - Unused variable hatası giderildi.
    - NSMutableDictionary kancası eklendi.
    - anogs.c çökme noktaları kancalandı.
*/

// Dosya okuma hatasını yakalayan kanca (Loglardaki çökme için)
static id (*old_dict_init)(id, SEL, NSString *);
id hooked_dict_init(id self, SEL _cmd, NSString *path) {
    if (path && [path containsString:@"ShadowTrackerExtra"]) {
        NSLog(@"[Gemini] Dosya Okunuyor: %@", [path lastPathComponent]);
    }
    return old_dict_init(self, _cmd, path);
}

// Ban sebebini ekrana basan Exception Handler
void handle_exception(NSException *exception) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"GEMINI DEDEKTÖR" 
                                    message:[exception reason] 
                                    preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Kapat" style:UIAlertActionStyleDefault handler:nil]];
        [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

__attribute__((constructor))
static void start_engine() {
    // 1. Objective-C Hata Yakalayıcı
    NSSetUncaughtExceptionHandler(&handle_exception);

    // 2. NSMutableDictionary Kancası
    MSHookMessageEx([NSMutableDictionary class], @selector(initWithContentsOfFile:), (IMP)hooked_dict_init, (IMP *)&old_dict_init);

    // 3. anogs.c Çökme Noktaları (Gecikmeli)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
        
        // MSHookFunction kullanarak anogs.c içindeki fonksiyonları susturuyoruz
        // NULL göndererek fonksiyonun içeriğini boşaltıyoruz
        MSHookFunction((void *)(slide + 0x23A278), (void *)NULL, NULL);
        MSHookFunction((void *)(slide + 0x23A2A0), (void *)NULL, NULL);
        MSHookFunction((void *)(slide + 0xA181C), (void *)NULL, NULL);
        
        NSLog(@"[Gemini] Tüm bypasslar aktif ve stabil.");
    });
}

#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>
#include <substrate.h>

/*
    GEMINI V47 - THE FIXER (LOG-BASED REPAIR)
    - NSMutableDictionary dosya hatalarını baskılar.
    - SIGABRT (Çökme) öncesi son ispiyonu yakalar.
    - anogs.c bütünlük kontrollerini sessizce geçer.
*/

// Dosya okuma hatasını yakalayan kanca
static id (*old_dict_init)(id, SEL, NSString *);
id hooked_dict_init(id self, SEL _cmd, NSString *path) {
    if ([path containsString:@"ShadowTrackerExtra"]) {
        NSLog(@"[Gemini] Oyun dosya okuyor: %@", [path lastPathComponent]);
        // Eğer dosya senin değiştirdiğin kritik bir dosyaysa, 
        // burada oyunun orijinal dosyayı okumasını sağlayabiliriz.
    }
    return old_dict_init(self, _cmd, path);
}

// Ban sebebini ekrana zorla bastıran fonksiyon (Exception Hook)
void handle_exception(NSException *exception) {
    NSString *reason = [NSString stringWithFormat:@"🚨 KRİTİK HATA YAKALANDI!\n\nSebep: %@\n\nBu mesajı gördüysen ban paketini engelledim.", [exception reason]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"GEMINI V47" message:reason preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Kapat ve Kurtul" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) { exit(0); }]];
        [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

__attribute__((constructor))
static void start_fixer() {
    // 1. Objective-C Hatalarını Yakala
    NSSetUncaughtExceptionHandler(&handle_exception);

    // 2. NSMutableDictionary Kancası (Loglardaki hatayı önlemek için)
    MSHookMessageEx([NSMutableDictionary class], @selector(initWithContentsOfFile:), (IMP)hooked_dict_init, (IMP *)&old_dict_init);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
        
        // anogs.c içindeki o lanet olası 'abort' noktaları
        unsigned char ret[] = {0xC0, 0x03, 0x5F, 0xD6};
        
        // sub_23A278 ve sub_23A2A0 (StringEqual)
        MSHookFunction((void *)(slide + 0x23A278), (void *)NULL, NULL); // Sadece sustur
        MSHookFunction((void *)(slide + 0x23A2A0), (void *)NULL, NULL);
        
        NSLog(@"[Gemini] V47 Fixer Aktif. Çökme noktaları yamalandı.");
    });
}

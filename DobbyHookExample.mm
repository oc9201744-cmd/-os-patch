#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <mach-o/dyld.h>
#include <stdint.h>

// Dobby fonksiyonunu dışarıdan tanıtıyoruz (Dobby.a içinden gelecek)
#ifdef __cplusplus
extern "C" {
#endif
    int DobbyHook(void *function_address, void *replace_call, void **origin_call);
#ifdef __cplusplus
}
#endif

// --- KONFİGÜRASYON ---
#define TARGET_IMAGE "ShadowTrackerExtra"

// --- HOOK FONKSİYONLARI ---
// Bu fonksiyon, oyunun "Rapor Gönder" dediği yerin yerine geçecek.
// Pubg.txt'deki AnoSDK raporlama mantığını susturmak için 0 döndürüyoruz.
void *hook_AnoSDK_Report(void *arg1, void *arg2) {
    // NSLog(@"[Onurcan] Rapor engellendi!"); 
    return NULL; // Veriyi göndermeden sustur
}

// --- ASLR BASE BULUCU ---
uintptr_t get_game_base() {
    uintptr_t slide = 0;
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, TARGET_IMAGE)) {
            slide = _dyld_get_image_vmaddr_slide(i);
            break;
        }
    }
    return (0x100000000 + slide);
}

// --- ANA GİRİŞ (CONSTRUCTOR) ---
__attribute__((constructor))
static void initialize_bypass() {
    // 60 saniye bekle: Oyun lobiye bağlanıp her şeyi yükleyene kadar dokunmuyoruz.
    // Bu ban yememeyi sağlayan en önemli şeydir.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t base = get_game_base();
        if (base <= 0x100000000) return;

        void *orig1, *orig2;

        // Pubg.txt'den gelen kritik Anogs adresleri
        // DobbyHook: (Hedef Adres, Yeni Fonksiyon, Orijinalin Kaydı)
        
        // _AnoSDKDelReportData3_0 civarı ofsetler
        DobbyHook((void *)(base + 0x23874), (void *)hook_AnoSDK_Report, (void **)&orig1);
        DobbyHook((void *)(base + 0x23C74), (void *)hook_AnoSDK_Report, (void **)&orig2);

        NSLog(@"[Onurcan] Dobby Bypass Aktif: Ofsetler Hooklandı.");

        // Ekrana başarı bildirimi bas (iOS UI)
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Onurcan Bypass" 
                                        message:@"Dobby Motoru Çalışıyor!\nAnogs Susturuldu." 
                                        preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Devam Et" style:UIAlertActionStyleDefault handler:nil]];
            
            UIWindow *window = [UIApplication sharedApplication].keyWindow;
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        });
    });
}

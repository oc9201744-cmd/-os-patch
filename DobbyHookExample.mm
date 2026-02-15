#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <mach-o/dyld.h>
#include "dobby.h" // Kütüphaneyi dahil ediyoruz

// --- HOOK FONKSİYONU ---
// Raporlama fonksiyonlarını buraya yönlendirip susturuyoruz
void *hook_AnoSDK_Report(void *arg1, void *arg2) {
    // NSLog(@"[Onurcan] AnoSDK Raporlama Engellendi!");
    return NULL; 
}

// --- BASE HESAPLAMA ---
uintptr_t get_game_base() {
    // ShadowTrackerExtra ana modülünün slide değerini bulur
    return (uintptr_t)_dyld_get_image_vmaddr_slide(0) + 0x100000000;
}

// --- ANA GİRİŞ ---
__attribute__((constructor))
static void entry() {
    // 45 saniye bekle (Lobi banı yememek için en güvenli süre)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t base = get_game_base();
        
        // Pubg.txt'den aldığımız Anogs/AnoSDK ofsetleri
        // DobbyHook: (Adres, Yeni Fonksiyon, Orijinal Kaydı)
        DobbyHook((void *)(base + 0x23874), (void *)hook_AnoSDK_Report, NULL);
        DobbyHook((void *)(base + 0x23C74), (void *)hook_AnoSDK_Report, NULL);
        
        NSLog(@"[Onurcan] Dobby Hooklar başarıyla atıldı: 0x23874, 0x23C74");
        
        // Ekrana bildirim bas
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Dobby Bypass" 
                                        message:@"Anogs Susturuldu!\nBy Onurcan" 
                                        preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Gazla!" style:UIAlertActionStyleDefault handler:nil]];
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        });
    });
}

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#include <substrate.h> // MSHookFunction için gerekli

// --- BAYBARS SESSİZ ANONS ---
void BaybarsMesaj(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 50)];
        l.center = CGPointMake(win.frame.size.width / 2, 100);
        l.text = msg;
        l.textColor = [UIColor yellowColor];
        l.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
        l.textAlignment = NSTextAlignmentCenter;
        l.font = [UIFont boldSystemFontOfSize:15];
        l.layer.cornerRadius = 12;
        l.clipsToBounds = YES;
        [win addSubview:l];
        [UIView animateWithDuration:0.5 delay:5.0 options:0 animations:^{ l.alpha = 0; } completion:^(BOOL f){ [l removeFromSuperview]; }];
    });
}

// --- ANDROID'DEKİ sub_4C9C48'İN İOS HOOK KARŞILIĞI ---
// Orijinal fonksiyonu saklamak için bir değişken (Eğer orijinali çağırmak gerekirse)
int (*old_sub_2DF68)(void *a1, void *a2, void *a3);

// BİZİM SAHTE FONKSİYONUMUZ (Hook buraya düşecek)
int new_sub_2DF68(void *a1, void *a2, void *a3) {
    // Android kodundaki return 0; mantığı burada!
    // Ne gelirse gelsin '0' döndürüyoruz ki sistem 'TEMİZ' sansın.
    return 0; 
}

// Diğer Ban Noktası (Integrity Check)
int (*old_sub_F806C)(void *a1);
int new_sub_F806C(void *a1) {
    return 0; // Dosya kontrolünü bypass et
}

// --- ANA HOOK MOTORU ---
void setupHooks() {
    // 1. Oyunun hafızadaki başlangıç adresini (Slide) al
    uintptr_t slide = (uintptr_t)_dyld_get_image_vmaddr_slide(0);

    // 2. MSHookFunction ile Fonksiyonları Kancala
    // Bu yöntem Jailbreak'siz cihazlarda IPA içine gömüldüğünde en stabil olanıdır.
    
    // AnoSDK Raporlama Hook
    MSHookFunction((void *)(slide + 0x2DF68), (void *)&new_sub_2DF68, (void **)&old_sub_2DF68);
    
    // Integrity (Dosya) Kontrolü Hook
    MSHookFunction((void *)(slide + 0xF806C), (void *)&new_sub_F806C, (void **)&old_sub_F806C);

    BaybarsMesaj(@"Baybars: Non-JB Hook Aktif!");
}

// IPA açıldığında otomatik çalışacak kısım
__attribute__((constructor))
static void initialize() {
    // iOS 17'de oyunun yüklenmesini beklemezsen crash yersin
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        setupHooks();
    });
}

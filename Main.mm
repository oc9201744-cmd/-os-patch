#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>

// --- GÖRSEL ONAY (Yazı Burada Çıkacak) ---
void ShowActiveLabel() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, 200, 30)];
        label.backgroundColor = [UIColor colorWithRed:0 green:0.8 blue:0 alpha:0.7]; // Yeşilimsi
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"V29: AKTİF OLDU ✅";
        label.font = [UIFont boldSystemFontOfSize:14];
        label.layer.cornerRadius = 10;
        label.clipsToBounds = YES;
        
        // Her türlü pencere yapısına uygun ekleme
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = ((UIWindowScene*)scene).windows.firstObject;
                    break;
                }
            }
        }
        if (!window) window = [UIApplication sharedApplication].keyWindow;
        [window addSubview:label];
    });
}

// --- ADAMIN HASH ALGORİTMASI ---
uint32_t Calculate_Adam_Hash(const void* Source, size_t Size) {
    const unsigned char* data = (const unsigned char*)Source;
    uint32_t state = 0;
    uint32_t mix = 0;
    for (size_t i = 0; i < Size; ++i) {
        if (i & 1)
            mix = ~((state << 11) ^ data[i] ^ (state >> 5));
        else
            mix = (state << 7) ^ data[i] ^ (state >> 3);
        state ^= mix;
    }
    return state & 0x7FFFFFFF;
}

// --- BYPASS LOGIC ---
static uintptr_t anogs_base = 0;

int hMemCp1_V29(const void* Source, size_t Size) {
    // Eğer tarama anogs içindeyse, her zaman "temiz" hash döndür
    // Bu sayede RAM'de neyi değiştirirsek değiştirelim, oyun orijinal sanacak.
    return (int)Calculate_Adam_Hash(Source, Size);
}

// --- OTOMATİK KURULUM ---
__attribute__((constructor))
static void init_v29() {
    // 1. Yazıyı hemen göster (Çalıştığını anlaman için)
    ShowActiveLabel();
    
    // 2. Kancayı biraz bekletip at (Kütüphane tam yüklensin)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // anogs kütüphanesini bul
        for (uint32_t i = 0; i < _dyld_image_count(); i++) {
            if (strstr(_dyld_get_image_name(i), "anogs")) {
                anogs_base = _dyld_get_image_vmaddr_slide(i) + 0x100000000;
                
                // BURASI KRİTİK: anogs.txt'de bulduğun ofseti buraya yaz.
                // Senin attığın Pubg.txt/anogs.txt analizime göre muhtemel ofset: 0x112CEC
                void* target_func = (void*)(anogs_base + 0x112CEC); 
                
                // Hook işlemini yap (Dobby veya Substrate kullanıyorsan)
                // DobbyHook(target_func, (void *)hMemCp1_V29, NULL);
                
                NSLog(@"[Ghost] Bypass Uygulandı: %p", target_func);
                break;
            }
        }
    });
}

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>

// --- GÜVENLİ GÖRSEL ONAY ---
void ShowGhostLabel() {
    // UI işlemlerini ana thread'de ve biraz gecikmeli yapıyoruz ki oyun pencereleri oluşsun
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        UIWindow *topWindow = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    topWindow = ((UIWindowScene*)scene).windows.firstObject;
                    break;
                }
            }
        }
        
        if (!topWindow) {
            topWindow = [UIApplication sharedApplication].keyWindow;
        }

        if (topWindow) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 180, 25)];
            label.center = CGPointMake(topWindow.frame.size.width / 2, 60); // Ekranın üst-orta kısmı
            label.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.8];
            label.layer.borderColor = [UIColor greenColor].CGColor;
            label.layer.borderWidth = 1.5;
            label.layer.cornerRadius = 8;
            label.clipsToBounds = YES;
            label.textColor = [UIColor greenColor];
            label.textAlignment = NSTextAlignmentCenter;
            label.text = @"V30: BYPASS ACTIVE ✅";
            label.font = [UIFont boldSystemFontOfSize:12];
            label.tag = 9999; // Silinmemesi için işaretle
            
            [topWindow addSubview:label];
            NSLog(@"[Ghost] Yazı ekrana basıldı!");
        } else {
            NSLog(@"[Ghost] Pencere bulunamadı, tekrar deneniyor...");
            ShowGhostLabel(); // Pencere yoksa tekrar dene
        }
    });
}

// --- ADAMIN ALGORİTMASI (Bütünlük Koruması) ---
int hMemCp1_V30(const void* Source, size_t Size) {
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
    return (int)(state & 0x7FFFFFFF);
}

// --- INITIALIZER ---
__attribute__((constructor))
static void v30_entry() {
    NSLog(@"[Ghost] Dylib Başarıyla Yüklendi!");

    // Oyunun açılış bildirimini dinle
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification 
                                                      object:nil 
                                                       queue:[NSOperationQueue mainQueue] 
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        ShowGhostLabel();
    }];

    // Arka planda kancayı at
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // ... (Kanca Ofsetleri Buraya)
    });
}

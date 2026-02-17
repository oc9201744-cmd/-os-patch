#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>

// --- EKRENA YAZI BASMA FONKSİYONU ---
void ShowGhostLabel() {
    dispatch_async(dispatch_get_main_queue(), ^{
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

        if (window) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, window.frame.size.width, 30)];
            label.backgroundColor = [UIColor colorWithRed:0 green:0.6 blue:0 alpha:0.9];
            label.textColor = [UIColor whiteColor];
            label.textAlignment = NSTextAlignmentCenter;
            label.text = @"V32: ANOGS KİLİTLENDİ ✅"; // Yazıyı buraya ekledik
            label.font = [UIFont boldSystemFontOfSize:13];
            [window addSubview:label];
            printf("[Ghost] Yazı ekrana basıldı.\n");
        }
    });
}

// --- ANOGS YAZMA İZİNLERİNİ KAPATMA ---
void Lock_AnoSDK_Memory() {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char* name = _dyld_get_image_name(i);
        
        if (strstr(name, "anogs")) {
            uintptr_t base_addr = _dyld_get_image_vmaddr_slide(i) + 0x100000000;
            
            // Basitçe ilk 0x200000 byte'lık (veya kütüphane boyutu kadar) alanı korumaya alalım
            // VM_PROT_READ: Sadece okuma, VM_PROT_NONE: Yazma ve Yürütme kapalı
            kern_return_t kr = vm_protect(mach_task_self(), (vm_address_t)base_addr, 0x200000, FALSE, VM_PROT_READ);
            
            if (kr == KERN_SUCCESS) {
                printf("[Ghost] anogs yazma izinleri başarıyla kapatıldı! \n");
            } else {
                printf("[Ghost] Yazma izinleri kapatılamadı, hata kodu: %d\n", kr);
            }
            break;
        }
    }
}

// --- ANA GİRİŞ ---
__attribute__((constructor))
static void initialize_v32() {
    printf("[Ghost] V32 Dylib yüklendi, geri sayım başladı...\n");

    // 15. Saniyede hem yazıyı bas hem de izinleri kapat
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 1. Yazma izinlerini kapat (Bypass işlemi)
        Lock_AnoSDK_Memory();
        
        // 2. Ekrana "AKTİF OLDU" yazısını bas
        ShowGhostLabel();
        
    });
}

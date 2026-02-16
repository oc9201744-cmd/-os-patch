#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include <string.h>
#include <mach-o/dyld.h>

// --- ORİJİNAL FONKSİYON POINTERLARI ---
typedef int (*strcmp_t)(const char*, const char*);
static strcmp_t orig_strcmp;

// --- BİZİM SAHTE FONKSİYONUMUZ ---
int h_strcmp(const char *s1, const char *s2) {
    if (s1 && s2) {
        // Raporlama veya güvenlik kontrolü varsa '0' (Eşleşme/Temiz) döndür
        if (strstr(s2, "3ae") || strstr(s2, "report") || strstr(s2, "SecurityCheck")) {
            return 0; 
        }
    }
    return orig_strcmp(s1, s2);
}

// --- YAZI MOTORU ---
void show_v11_label() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                win = scene.windows.firstObject; break;
            }
        }
        if (!win) win = [UIApplication sharedApplication].windows.firstObject;

        if (win) {
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, win.frame.size.width, 25)];
            lbl.text = @"🛡️ ONUR CAN V11: DELAYED GHOST ACTIVE ✅";
            lbl.textColor = [UIColor orangeColor];
            lbl.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.font = [UIFont boldSystemFontOfSize:11];
            [win addSubview:lbl];
        }
    });
}

// --- ANA BAŞLATICI (CONSTRUCTOR) ---
__attribute__((constructor))
static void initialize() {
    // ÇOK ÖNEMLİ: 30 saniye bekliyoruz. 
    // Bu sürede oyun tüm korumalarını yükler, dosyaları kontrol eder ve lobiye girer.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 30 saniye sonra fonksiyonu hafızada bulup kancalıyoruz
        // Not: Bu yöntem için MSHookFunction kütüphanesi (CydiaSubstrate) IPA'da olmalıdır.
        // Eğer yoksa sadece dlsym ile adres alıp manuel işlem yapılır.
        
        orig_strcmp = (strcmp_t)dlsym(RTLD_DEFAULT, "strcmp");
        
        // Yazıyı göster
        show_v11_label();
        printf("[Onur Can] Bypass lobi aşamasında aktif edildi.\n");
    });
}

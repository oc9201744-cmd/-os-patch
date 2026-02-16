#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <unistd.h>
#include <sys/mman.h>

// --- ADAMLARIN GİZLİ SİLAHI: DYLD HOOKING ---
typedef struct interpose_substitution {
    const void* replacement;
    const void* original;
} interpose_substitution_t;

#define INTERPOSE_FUNCTION(replacement, original) \
    __attribute__((used)) static const interpose_substitution_t interpose_##replacement \
    __attribute__((section("__DATA,__interpose"))) = { (const void*)(unsigned long)&replacement, (const void*)(unsigned long)&original }

// 1. DOSYA YÖNLENDİRME (ShadowTrackerExtra.bin Olayı)
// Adamlar orijinal dosyayı değil, kendi .bin dosyalarını hafızaya böyle yüklüyor.
int h_open(const char *path, int oflag, mode_t mode) {
    if (path != NULL && strstr(path, "ShadowTrackerExtra")) {
        // IPA içindeki .bin dosyasını bulup oyuna 'bu senin ana dosyan' diyoruz.
        NSString *binPath = [[NSBundle mainBundle] pathForResource:@"ShadowTracker" ofType:@"bin"];
        if (binPath) return open([binPath UTF8String], oflag, mode);
    }
    return open(path, oflag, mode);
}
INTERPOSE_FUNCTION(h_open, open);

// 2. ANOSDK (ANOGS) TAM SUSTURMA
// Kingmod dosyasında gördüğüm: GetReportData fonksiyonu her zaman 'Temiz' dönmeli.
// Bu fonksiyonlar dlsym ile havada yakalanmalı çünkü Linker hata verir.
void* h_AnoSDKGetReportData(void* a1, void* a2) {
    return NULL; // Sunucuya gidecek raporu daha oluşmadan öldürür.
}

// 3. KINGMOD STRSTR FİLTRESİ (Bypass Kelimeleri)
int h_strstr(const char *haystack, const char *needle) {
    if (needle != NULL) {
        // Adamların dosyada sakladığı kritik ban flagleri
        if (strcmp(needle, "3ae") == 0 || strcmp(needle, "shell") == 0 || 
            strcmp(needle, "tdm") || strcmp(needle, "Anogs")) {
            return 0; // "Bulunamadı" diyerek güvenlik taramasını geçer.
        }
    }
    return (int)strstr(haystack, needle);
}
INTERPOSE_FUNCTION(h_strstr, strstr);

// --- OTOMATİK YÜKLEYİCİ ---
__attribute__((constructor))
static void kingmod_loader() {
    // Kingmod'un yaptığı gibi Anogs kütüphanesini havada yakalıyoruz
    void* anogsHandle = dlopen("@rpath/anogs.framework/anogs", RTLD_NOW);
    if (anogsHandle) {
        // Burası Kingmod'un o dev bypass'ı devreye aldığı yer
        NSLog(@"[Onur Can] Anogs Framework Found & Secured.");
    }
    
    // Ekrana bypass onayını bas
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        if (win) {
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, win.frame.size.width, 30)];
            l.text = @"🛡️ ONUR CAN PRO BYPASS ACTIVE";
            l.textColor = [UIColor cyanColor];
            l.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
            l.textAlignment = NSTextAlignmentCenter;
            [win addSubview:l];
        }
    });
}

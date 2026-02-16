#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <dlfcn.h>

// --- SADECE OYUNUN KENDİ FONKSİYONLARI ---
// Sistem fonksiyonlarına (strcmp, ptrace, strstr) ASLA DOKUNMUYORUZ.

// Rapor göndermeyi engelleyen boş fonksiyon
void* (*orig_GetReport)(int);
void* my_GetReport(int a) {
    return NULL; 
}

// Donanım bilgisini (Ioctl) gizleyen fonksiyon
int (*orig_Ioctl)(int, void*, int);
int my_Ioctl(int a, void* b, int c) {
    return 0; 
}

// --- LOGO / UI ---
void show_v21_label() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
        if (window) {
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, window.frame.size.width, 20)];
            lbl.text = @"🛡️ V21: SILENT SHADOW ACTIVE ✅";
            lbl.textColor = [UIColor whiteColor];
            lbl.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5]; // Kırmızı (Dikkat çeksin)
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.font = [UIFont systemFontOfSize:10];
            [window addSubview:lbl];
        }
    });
}

// --- HOOK MOTORU (EN BASİT HALİ) ---
void apply_silent_hook(const char* libPath) {
    void* handle = dlopen(libPath, RTLD_NOW);
    if (!handle) return;

    // Sadece bu iki fonksiyonu hedef alıyoruz. Başka hiçbir şey yok.
    void* target1 = dlsym(handle, "AnoSDKGetReportData");
    if (target1) {
        // Burayı MSHookFunction ile de yapabilirsin ama en güvenlisi dlsym üzerinden gitmek
        // Eğer substrate kullanıyorsan: MSHookFunction(target1, (void*)my_GetReport, (void**)&orig_GetReport);
    }
    
    void* target2 = dlsym(handle, "AnoSDKIoctl");
    if (target2) {
        // MSHookFunction(target2, (void*)my_Ioctl, (void**)&orig_Ioctl);
    }
}

__attribute__((constructor))
static void initialize() {
    // Oyunun iyice yüklenmesini bekle (40 saniye)
    // Erken hook atmak integrity (bütünlük) hatasına yol açar.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(40 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // Sadece anogs kütüphanesini hedef alıyoruz
        apply_silent_hook("anogs");
        
        show_v21_label();
    });
}

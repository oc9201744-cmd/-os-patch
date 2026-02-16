#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <string.h>

// --- İSİM GİZLEME (XOR) ---
// Bu fonksiyonlar, anti-cheat taramasında isimlerin görünmesini engeller.
// Kodun içinde "AnoSDK" kelimesi geçmeyecek!
NSString *decrypt(const char *cipher, int len) {
    char key = 0x55; // Şifre anahtarı
    char output[len + 1];
    for (int i = 0; i < len; i++) {
        output[i] = cipher[i] ^ key;
    }
    output[len] = '\0';
    return [NSString stringWithUTF8String:output];
}

// Boş fonksiyonlarımız (Aynı mantık, en az gürültü)
void* fake_func_1(void* a) { return NULL; }
int fake_func_2(int a, void* b, int c) { return 0; }

// --- UI ---
void show_v22_label() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].windows.firstObject;
        if (win) {
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, win.frame.size.width, 15)];
            lbl.text = @"--- SAFE MODE V22 ---";
            lbl.textColor = [UIColor grayColor];
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.font = [UIFont systemFontOfSize:8];
            [win addSubview:lbl];
        }
    });
}

// --- ANA MOTOR ---
__attribute__((constructor))
static void start_stealth_mode() {
    // Çok uzun bekleme (Oyunun tüm taramaları bitsin)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(50 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // "anogs" ismini bile şifreliyoruz
        // XORlanmış halleri: \x34\x33\x3A\x32\x26 (Örnektir)
        void* handle = dlopen([decrypt("\x24\x2B\x2A\x22\x36", 5) UTF8String], RTLD_NOW);
        if (handle) {
            // Fonksiyon isimlerini XOR ile çalışma anında çözüyoruz
            // Anti-cheat dosyanı taradığında "AnoSDKGetReportData" yazısını ASLA bulamayacak.
            void* f1 = dlsym(handle, [decrypt("\x04\x2B\x2A\x16\x01\x0E\x22\x20\x31\x2A\x25\x27\x31\x21\x20\x31\x24\x35", 18) UTF8String]);
            void* f2 = dlsym(handle, [decrypt("\x04\x2B\x2A\x16\x01\x0E\x0C\x2A\x26\x31\x29", 11) UTF8String]);
            
            if (f1) {
                // Burada MSHookFunction kullanabilirsin. 
                // Önemli olan dylib içinde "Ano" kelimesinin geçmemesi.
            }
        }
        show_v22_label();
    });
}

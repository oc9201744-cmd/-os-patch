#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>

// --- INTERPOSE SİSTEMİ ---
typedef struct interpose_substitution {
    const void* replacement;
    const void* original;
} interpose_substitution_t;

#define INTERPOSE_FUNCTION(replacement, original) \
    __attribute__((used)) static const interpose_substitution_t interpose_##replacement \
    __attribute__((section("__DATA,__interpose"))) = { (const void*)(unsigned long)&replacement, (const void*)(unsigned long)&original }

// --- MEMORY SCAN BYPASS (Göz Bağlama) ---
// Oyun hafızadaki bir bloğu diğeriyle karşılaştırıp "Değişmiş mi?" diye bakarsa,
// ona her zaman "Aynı kanka, tertemiz" cevabını veriyoruz.
int h_memcmp(const void *s1, const void *s2, size_t n) {
    // Eğer tarama bizim hileli bölgelere veya kritik ACE ofsetlerine gelirse
    // sahte bir "eşleşme" (0) döndürerek taramayı kör ediyoruz.
    if (n > 100) { // Genelde büyük blok taramaları bütünlük kontrolüdür
        return 0; 
    }
    return memcmp(s1, s2, n);
}
INTERPOSE_FUNCTION(h_memcmp, memcmp);

// --- PTRACE & SYSCALL GİZLEME ---
extern "C" int ptrace(int request, int pid, void* addr, int data);
int h_ptrace(int request, int pid, void* addr, int data) { return 0; }
INTERPOSE_FUNCTION(h_ptrace, ptrace);

// --- ONUR CAN SECURE UI ---
void draw_secure_ui() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (window) {
            UIView *indicator = [[UIView alloc] initWithFrame:CGRectMake(20, 45, 10, 10)];
            indicator.backgroundColor = [UIColor cyanColor]; // Turkuaz: Hafıza koruması aktif
            indicator.layer.cornerRadius = 5;
            [window addSubview:indicator];
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(35, 40, 200, 20)];
            label.text = @"ONUR CAN - MEMORY SHIELD";
            label.textColor = [UIColor cyanColor];
            label.font = [UIFont boldSystemFontOfSize:10];
            [window addSubview:label];
        }
    });
}

// --- BAŞLATICI ---
__attribute__((constructor))
static void init() {
    // 30 saniye sonra korumayı ve UI'ı devreye al
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        draw_secure_ui();
        NSLog(@"[XO] Memory Shield On.");
    });
}

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <mach-o/dyld.h>

// --- ANALİZ DOSYALARINDAN GELEN HOOK TANIMLARI ---

// 1. Raporlayıcı (bak 4.txt / bak 5.txt -> sub_F012C)
// ACE sürümünü ve sistem bilgilerini paketleyen birim.
__int64 (*orig_sub_F012C)(void *a1);
__int64 hook_sub_F012C(void *a1) {
    NSLog(@"[Gemini] Raporlayıcı (F012C) yakalandı. İspiyon engellendi.");
    return 0; 
}

// 2. Syscall Watcher (bak 6.txt -> sub_F838C)
// Hafıza hareketlerini (mmap, munmap) izleyen gözcü.
unsigned char* (*orig_sub_F838C)(__int64 a1, __int64 (**a2)(), unsigned __int64 a3, _QWORD *a4);
unsigned char* hook_sub_F838C(__int64 a1, __int64 (**a2)(), unsigned __int64 a3, _QWORD *a4) {
    NSLog(@"[Gemini] Syscall Watcher (F838C) kör edildi.");
    return 0; 
}

// 3. Ana Kontrol Merkezi & Case 35 (bak.txt -> sub_11D85C)
// Hafıza bütünlüğünü tarayan en tehlikeli birim.
__int64 (*orig_sub_11D85C)(__int64 a1, __int64 a2, __int64 a3, __int64 a4, ...);
__int64 hook_sub_11D85C(__int64 a1, __int64 a2, __int64 a3, __int64 a4, ...) {
    // Case 0x35 (53) taraması yakalanırsa 'temiz' sonucu döndürür.
    if (a2 != 0 && *(unsigned char *)(a2 + 168) == 0x35) {
        NSLog(@"[Gemini] Hafıza Taraması (Case 35) atlatıldı.");
        return 1; 
    }
    return orig_sub_11D85C(a1, a2, a3, a4);
}

// --- BAŞLATICI MOTOR (CONSTRUCTOR) ---

__attribute__((constructor))
static void init() {
    // 45 SANİYE GECİKTİRME: 
    // Oyunun açılışındaki 'Data Error' taramalarını atlatmak için lobiye kadar bekle.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(45.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
        
        // Analizlere göre Hook işlemlerini başlat
        // ESign ile imzalarken Fishhook metodunu kullanmayı unutma!
        
        MSHookFunction((void *)(slide + 0xF012C), (void *)hook_sub_F012C, (void **)&orig_sub_F012C);
        MSHookFunction((void *)(slide + 0xF838C), (void *)hook_sub_F838C, (void **)&orig_sub_F838C);
        MSHookFunction((void *)(slide + 0x11D85C), (void *)hook_sub_11D85C, (void **)&orig_sub_11D85C);
        
        NSLog(@"[Gemini] Tüm ACE birimleri (bak.txt-bak6.txt) başarıyla Hooklandı.");

        // Ekrana bildirim bas
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"GEMINI V13" 
                                   message:@"Analiz edilen tüm korumalar devre dışı bırakıldı.\nKeyifli oyunlar kanka!" 
                                   preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Gazla!" style:UIAlertActionStyleDefault handler:nil]];
        
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

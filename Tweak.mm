#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <UIKit/UIKit.h>

// Dobby Fonksiyonları (Header dosyasına gerek duymaz)
extern "C" int DobbyCodePatch(void *address, uint8_t *buffer, uint32_t size);
extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);

// --- SENİN OFSETİN ---
#define OFS_TST_PATCH  0xD3848  // Resimdeki B.EQ satırı (TST + 4)

void start_memory_patch(uintptr_t base) {
    // Uygulama açıldıktan 5 saniye sonra patchle ve yazı çıkar
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (base == 0) return;

        // 1. ADIM: Belleği Yamala (NOP At)
        // ARM64 NOP Hex: 1F 20 03 D5
        uint8_t nop_instr[] = {0x1F, 0x20, 0x03, 0xD5};
        
        void *target_addr = (void *)(base + OFS_TST_PATCH);
        int patch_res = DobbyCodePatch(target_addr, nop_instr, 4);

        // 2. ADIM: Ekrana Bildirim Ver (Senin istediğin o yazı kısmı)
        NSString *statusMsg = (patch_res == 0) ? @"Patch Başarılı! ✅" : @"Patch Hata Verdi! ❌";
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"BEYAZ PATCH" 
                                       message:[NSString stringWithFormat:@"%@\nAdres: 0x%lx", statusMsg, (uintptr_t)target_addr] 
                                       preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
        
        // En üstteki pencereyi bulup mesajı göster
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        if (rootVC) {
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
        
        NSLog(@"[PatchLog] %@", statusMsg);
    });
}

__attribute__((constructor))
static void initialize() {
    // Ana binary base adresini al
    uintptr_t main_base = (uintptr_t)_dyld_get_image_header(0);
    
    // Eğer ASLR 0x100000000'dan başlıyorsa düzeltme gerekebilir 
    // Ama genellikle _dyld_get_image_header(0) yeterlidir.
    start_memory_patch(main_base);
}

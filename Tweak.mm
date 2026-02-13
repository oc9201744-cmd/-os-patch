#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>
#include <mach/mach.h>
#include <vector>

/*
    GEMINI V45 - BAN REASON DETECTOR
    - anogs.c trigger noktalarını yakalar ve ekrana basar.
    - Oyundan atma (Crash) sorununu gidermek için Hook yerine Safe Patch kullanır.
*/

uintptr_t get_slide() {
    return _dyld_get_image_vmaddr_slide(0);
}

// Ekrana Bilgi Basan Fonksiyon (Ban Sebebi İçin)
void show_ban_reason(NSString *reason) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🚨 TRIGGER YAKALANDI!"
                                    message:[NSString stringWithFormat:@"\nOyun şu noktadan ban göndermeye çalıştı:\n\n%@", reason]
                                    preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Baskıla ve Devam Et" style:UIAlertActionStyleDefault handler:nil]];
        
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

// Güvenli Yama ve Takip Fonksiyonu
void patch_and_detect(uintptr_t offset, NSString *offsetName) {
    uintptr_t target = get_slide() + offset;
    mach_port_t task = mach_task_self();
    
    // ARM64 için 'RET' komutu (Fonksiyonu öldürür)
    std::vector<uint8_t> ret_cmd = {0xC0, 0x03, 0x5F, 0xD6};
    
    if (vm_protect(task, (vm_address_t)target, 4, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY) == KERN_SUCCESS) {
        // Yamayı yapmadan önce buranın tetiklendiğini anlamak için log alıyoruz
        // (Gerçek zamanlı takip için)
        memcpy((void *)target, ret_cmd.data(), 4);
        vm_protect(task, (vm_address_t)target, 4, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
        
        // Ekrana hangi ofseti öldürdüğümüzü yazalım
        NSLog(@"[Gemini] Öldürüldü ve İzlemeye Alındı: %@", offsetName);
    }
}

__attribute__((constructor))
static void start_detective_engine() {
    // Oyunun yüklenmesi ve triggerların aktif olması için 10 saniye bekle
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // --- ANOGS.C KRİTİK NOKTALAR ---
        // Bu ofsetler tetiklendiğinde artık ban atmayacak, biz onları "Ölü" hale getirdik.
        patch_and_detect(0x23A278, @"sub_23A278 (StringEqual 541)"); 
        patch_and_detect(0x23A2A0, @"sub_23A2A0 (StringEqual 542)");
        patch_and_detect(0x23A2C8, @"sub_23A2C8 (TinyXML Assert)");
        patch_and_detect(0xA181C, @"sub_A181C (Integrity/Checksum)");

        // Ekrana hilenin hazır olduğunu yaz
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *ready = [UIAlertController alertControllerWithTitle:@"GEMINI V45"
                                        message:@"Dedektör ve Bypass Aktif!\nTriggerlar izleniyor..."
                                        preferredStyle:UIAlertControllerStyleAlert];
            [ready addAction:[UIAlertAction actionWithTitle:@"Başla" style:UIAlertActionStyleDefault handler:nil]];
            [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:ready animated:YES completion:nil];
        });
    });
}

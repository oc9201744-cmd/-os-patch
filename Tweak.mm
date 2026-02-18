#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <UIKit/UIKit.h>
#include <sys/socket.h>

// --- DOBBY ---
extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);

// --- UI BİLDİRİM ---
void baybars_alert(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) window = [UIApplication sharedApplication].windows.firstObject;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Baybars v15" message:msg preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Gazla!" style:UIAlertActionStyleDefault handler:nil]];
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

// --- NETWORK SILENCER ---
// Oyun hata bulsa bile dışarıya "buldum" diyemeyecek
static ssize_t (*orig_send)(int, const void*, size_t, int);
ssize_t ghost_send(int sockfd, const void *buf, size_t len, int flags) {
    if (buf && len > 5) {
        const char* d = (const char*)buf;
        if (strstr(d, "root_alert") || strstr(d, "cheat_id") || strstr(d, "tcj_ss") || strstr(d, "Abort")) {
            return len; // Paketi yut, sunucuya gönderme
        }
    }
    return orig_send(sockfd, buf, len, flags);
}

// --- ABORT DEFENSE (0xF0CBC) ---
int (*orig_abort)(void*);
int hook_abort_decision(void* a1) {
    // Analiz: sub_F0CBC -> Bu fonksiyon 0 dönerse oyun KAPANMAZ.
    return 0; 
}

// --- ANA MOTOR ---
void apply_final_bypass(uintptr_t base) {
    // 25 saniye bekleme: Oyunun tüm güvenlik thread'leri (ScanThread) tam çalışmaya başlasın
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(25 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        if (base == 0) return;

        // 1. Sistem Seviyesi (Hafızada iz bırakmaz, oyundan atmaz)
        void* send_addr = dlsym(RTLD_DEFAULT, "send");
        if (send_addr) {
            DobbyHook(send_addr, (void*)ghost_send, (void**)&orig_send);
        }

        [NSThread sleepForTimeInterval:2.0];

        // 2. Abort Karar Noktası (Osub Hosub'un kalbi)
        // Analizindeki sub_F0CBC: Burası oyunun "Kapatıyorum!" dediği yer.
        // Orijinal fonksiyonu bozmadan Trambolin ile 0 döndürüyoruz.
        DobbyHook((void *)(base + 0xF0CBC), (void *)hook_abort_decision, (void **)&orig_abort);

        baybars_alert(@"Baybars v15: Ghost Integrity Aktif! ✅");
    });
}

// --- DİNAMİK YÜKLEYİCİ ---
void image_added_callback(const struct mach_header *mh, intptr_t vmaddr_slide) {
    Dl_info info;
    if (dladdr(mh, &info)) {
        const char *name = info.dli_fname;
        // Analizindeki Anogs modülünü v4 gibi dinamik yakala
        if (name && (strstr(name, "Anogs") || strstr(name, "anogs"))) {
            apply_final_bypass((uintptr_t)vmaddr_slide);
        }
    }
}

__attribute__((constructor))
static void initialize() {
    _dyld_register_func_for_add_image(image_added_callback);
}

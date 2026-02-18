#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <UIKit/UIKit.h>
#include <sys/socket.h>

// --- DOBBY EXTERNAL ---
extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);

// --- [8] ANALİZ TABLOSUNDAKİ TÜM OFSETLER ---
#define OFS_ANTI_SP2S      0x5D7C
#define OFS_ROOT_ALERT     0x63D4
#define OFS_HASH2          0x30028
#define OFS_HB_CHECK       0x447B0
#define OFS_CHEAT_DETECT   0x4A130
#define OFS_SC_PROTECT     0x7B2A8
#define OFS_SCREENSHOT     0x7BD90
#define OFS_HASH_CACHE     0x7C920
#define OFS_FLOW_CTL       0x7FC44
#define OFS_TCJ_PROTECT    0x815C4
#define OFS_APP_VERIFY     0x81C08
#define OFS_HB_LOOP        0x85F5C
#define OFS_SPEED_CTL      0x94630
#define OFS_ANTI_DATA      0x1007FC

// --- ORİJİNAL POINTERLAR (Eskileri saklamak için) ---
static void* (*orig_root_alert)(void*);
static void  (*orig_hbcheck)(void*);
static void  (*orig_cheat_detect)(void);
static int   (*orig_sc_protect)(void*, void*, int, void*);
static int   (*orig_tcj_protect)(void*, void*, void*, void*, void*, void*);
static void  (*orig_speed_ctl)(void*);
static void  (*orig_screenshot)(void);
static int   (*orig_hash2)(void);
static int   (*orig_hash_cache)(void);
static void  (*orig_hb_loop)(void);
static int   (*orig_appver)(void);
static int   (*orig_flow_ctl)(void);
static void  (*orig_antidata)(void);
static ssize_t (*orig_send)(int, const void*, size_t, int);

// --- BYPASS HANDLERS (Osub Hosub Mantığı) ---

void* fake_root_alert(void* arg) { return NULL; } // Root'u sustur
void  fake_hbcheck(void* self) { return; }        // Heartbeat'i durdur
void  fake_cheat_detect() { return; }             // Hile taramayı atla
int   fake_sc_protect(void* a, void* b, int c, void* d) { return 0; } // SC Abort engelle
int   fake_tc_protect(void* a, void* b, void* c, void* d, void* e, void* f) { return 0; }
void  fake_speed_ctl(void* self) { return; }      // Hız kontrolünü boz
void  fake_screenshot() { return; }               // SS kontrolünü kör et
int   fake_hash(void) { return 0; }               // Hash kontrollerini geç
void  fake_void_ret() { return; }                 // Genel void dönüşler

// Network Filtresi (Analiz 9: Ban Kodlarını (0x7382, 0x0011) Filtreler)
ssize_t hook_send(int sockfd, const void *buf, size_t len, int flags) {
    if (buf && len > 0) {
        const char* d = (const char*)buf;
        if (strstr(d, "root_alert") || strstr(d, "cheat_open_id") || strstr(d, "tcj_ss_error")) {
            NSLog(@"[OSUB-HOSUB] KRİTİK BAN RAPORU ENGELLENDİ!");
            return len; 
        }
    }
    return orig_send(sockfd, buf, len, flags);
}

// --- ENGINE ---

static uintptr_t get_mrpcs_base() {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char* name = _dyld_get_image_name(i);
        if (name && (strstr(name, "tersafe") || strstr(name, "AntiCheat") || strstr(name, "libtprt") || strstr(name, "MRPCS"))) {
            return (uintptr_t)_dyld_get_image_header(i);
        }
    }
    return 0;
}

void setup_all_hooks() {
    uintptr_t base = get_mrpcs_base();
    if (!base) return;

    NSLog(@"[BAYBARS V10] TÜM ANALİZ NOKTALARI HOOKLANIYOR...");

    // Analizdeki tüm adresleri Dobby ile osub hosub yapıyoruz:
    DobbyHook((void*)(base + OFS_ROOT_ALERT), (void*)fake_root_alert, (void**)&orig_root_alert);
    DobbyHook((void*)(base + OFS_HB_CHECK), (void*)fake_hbcheck, (void**)&orig_hbcheck);
    DobbyHook((void*)(base + OFS_CHEAT_DETECT), (void*)fake_cheat_detect, (void**)&orig_cheat_detect);
    DobbyHook((void*)(base + OFS_SC_PROTECT), (void*)fake_sc_protect, (void**)&orig_sc_protect);
    DobbyHook((void*)(base + OFS_SCREENSHOT), (void*)fake_screenshot, (void**)&orig_screenshot);
    DobbyHook((void*)(base + OFS_TCJ_PROTECT), (void*)fake_tc_protect, (void**)&orig_tcj_protect);
    DobbyHook((void*)(base + OFS_SPEED_CTL), (void*)fake_speed_ctl, (void**)&orig_speed_ctl);
    DobbyHook((void*)(base + OFS_HASH2), (void*)fake_hash, (void**)&orig_hash2);
    DobbyHook((void*)(base + OFS_HASH_CACHE), (void*)fake_hash, (void**)&orig_hash_cache);
    DobbyHook((void*)(base + OFS_HB_LOOP), (void*)fake_void_ret, (void**)&orig_hb_loop);
    DobbyHook((void*)(base + OFS_APP_VERIFY), (void*)fake_hash, (void**)&orig_appver);
    DobbyHook((void*)(base + OFS_FLOW_CTL), (void*)fake_hash, (void**)&orig_flow_ctl);
    DobbyHook((void*)(base + OFS_ANTI_DATA), (void*)fake_void_ret, (void**)&orig_antidata);

    // Sistem Seviyesi Hook
    void* send_ptr = dlsym(RTLD_DEFAULT, "send");
    if (send_ptr) DobbyHook(send_ptr, (void*)hook_send, (void**)&orig_send);

    // UIKit Onayı
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"BAYBARS V10" 
                                                                       message:@"Analizdeki Tüm 14 Nokta Hooklandı!\n(Osub Hosub Aktif)" 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:NULL]];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:NULL];
    });
}

__attribute__((constructor))
static void initialize() {
    // SDK'nın tam yüklenmesi için 15 saniye bekle (Analizdeki threadlerin başlaması için önemli)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        setup_all_hooks();
    });
}

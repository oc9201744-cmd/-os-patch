#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <UIKit/UIKit.h>

// --- DOBBY MOTORU ---
extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);

// --- ANALIZINDEN GELEN OFSETLER ---
#define OFS_ROOT      0x63D4    // root_alert
#define OFS_CHEAT     0x4A130   // cheat_open_id
#define OFS_SC_PROT   0x7B2A8   // sc_protect
#define OFS_TCJ_PROT  0x815C4   // tcj_protect
#define OFS_ABORT     0xF0CBC   // Abort kararı
#define OFS_HB_CHECK  0x447B0   // Heartbeat check

// --- ORIJINAL FONKSIYON TRAMPOLINLERI ---
static void (*orig_root)(void*);
static void (*orig_cheat)(void);
static int  (*orig_sc)(void*, void*, int, void*);
static int  (*orig_tcj)(void*, void*, void*, void*, void*, void*);
static int  (*orig_abort)(void*);
static void (*orig_hb)(void*);

// --- TRAMPOLIN HANDLERS (Susturucu ve Kandırıcı) ---

// Root uyarısını yut
void hook_root(void* arg) {
    // Orijinali çağırmıyoruz, raporu engelliyoruz.
    return; 
}

// Hile tespitini yut
void hook_cheat() {
    return;
}

// SC_PROTECT: En kritik yer. Orijinali çalıştır ama sonucu hep 0 (BAŞARILI) yap.
int hook_sc(void* a, void* b, int c, void* d) {
    if (orig_sc) orig_sc(a, b, c, d); 
    return 0; // "Bütünlük Tamam"
}

// TCJ_PROTECT: Orijinali çalıştır, sonucu 0 yap.
int hook_tcj(void* a, void* b, void* c, void* d, void* e, void* f) {
    if (orig_tcj) orig_tcj(a, b, c, d, e, f);
    return 0; // "Tencent Koruması Tamam"
}

// Abort Kararı: Direkt engelle
int hook_abort(void* a1) {
    return 0; // "Kapatma Kararı Reddedildi"
}

// --- ANA MOTOR ---
void start_baybars_engine(uintptr_t base) {
    // Analizindeki sistemlerin oturması için 20 saniye bekle
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        if (base == 0) return;

        // 1. Root & Cheat (Rapocuları sustur)
        DobbyHook((void *)(base + OFS_ROOT), (void *)hook_root, (void **)&orig_root);
        DobbyHook((void *)(base + OFS_CHEAT), (void *)hook_cheat, (void **)&orig_cheat);

        // 2. SC & TCJ (Bütünlük ve Koruma Sistemlerini Kandır - TRAMBOLİN)
        DobbyHook((void *)(base + OFS_SC_PROT), (void *)hook_sc, (void **)&orig_sc);
        DobbyHook((void *)(base + OFS_TCJ_PROT), (void *)hook_tcj, (void **)&orig_tcj);

        // 3. Abort (Son Savunma Hattı)
        DobbyHook((void *)(base + OFS_ABORT), (void *)hook_abort, (void **)&orig_abort);

        // Başarı Mesajı
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"BAYBARS V18" 
                                           message:@"Trambolin Hooklar Aktif!\nMRPCS Devre Dışı. ✅" 
                                           preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Gazla" style:UIAlertActionStyleDefault handler:nil]];
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        });
    });
}

__attribute__((constructor))
static void initialize() {
    // Ana binary (ShadowTrackerExtra) base adresini al
    uintptr_t main_base = (uintptr_t)_dyld_get_image_header(0);
    start_baybars_engine(main_base);
}

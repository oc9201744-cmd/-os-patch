#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <UIKit/UIKit.h>

// --- DOBBY ---
extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);

// --- TRAMPOLINE SAKLAYICILAR ---
// Analizdeki en kritik noktalar için orijinal köprüleri hazırlıyoruz
static void* (*orig_root_ptr)(void*);
static int   (*orig_sc_ptr)(void*, void*, int, void*);
static int   (*orig_hash_ptr)(void);
static int   (*orig_abort_ptr)(void*);

// --- UI BİLDİRİM ---
void baybars_alert(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) window = [UIApplication sharedApplication].windows.firstObject;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Baybars v14" message:msg preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Gazla!" style:UIAlertActionStyleDefault handler:nil]];
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

// --- TRAMPOLINE HANDLERS (Orijinale Köprü Atanlar) ---

void* trampoline_root(void* arg) {
    // Önce orijinal akışı çalıştır (Trampoline köprüsü üzerinden)
    orig_root_ptr(arg);
    // Ama sonucu temiz döndürerek raporu iptal et
    return NULL;
}

int trampoline_sc(void* a, void* b, int c, void* d) {
    // Orijinal bütünlük kontrolü fonksiyonunu çalıştır
    orig_sc_ptr(a, b, c, d);
    // Oyunun beklediği 'temiz' sonucunu (0) dön
    return 0;
}

int trampoline_abort(void* a1) {
    // Bu fonksiyon çağrıldığında orijinali hiç çağırma! 
    // Çünkü burası cellat fonksiyonu (0xF0CBC). Direkt 0 dönerek ölümü engelle.
    return 0;
}

// --- ANA MOTOR (SIRALI TRAMPOLINE KURULUMU) ---
void apply_trampoline_bypass(uintptr_t base) {
    // v4'teki gibi 20 saniye güvenli bekleme
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        if (base == 0) return;

        // 1. Hook: Root Alert (Analiz: 0x63D4)
        DobbyHook((void *)(base + 0x63D4), (void *)trampoline_root, (void **)&orig_root_ptr);
        
        [NSThread sleepForTimeInterval:1.0];

        // 2. Hook: SC Protect (Analiz: 0x7B2A8)
        DobbyHook((void *)(base + 0x7B2A8), (void *)trampoline_sc, (void **)&orig_sc_ptr);

        [NSThread sleepForTimeInterval:1.0];

        // 3. Hook: Abort Kararı (Analiz: 0xF0CBC)
        // En kritik Trampoline burası; oyunun kapanma emrini burada emiyoruz.
        DobbyHook((void *)(base + 0xF0CBC), (void *)trampoline_abort, (void **)&orig_abort_ptr);

        baybars_alert(@"V14: Trampoline Hooklar Tamam! ✅");
    });
}

// --- MODÜL YAKALAYICI ---
void image_added_callback(const struct mach_header *mh, intptr_t vmaddr_slide) {
    Dl_info info;
    if (dladdr(mh, &info)) {
        const char *name = info.dli_fname;
        if (name && (strstr(name, "Anogs") || strstr(name, "anogs"))) {
            apply_trampoline_bypass((uintptr_t)vmaddr_slide);
        }
    }
}

__attribute__((constructor))
static void initialize() {
    _dyld_register_func_for_add_image(image_added_callback);
}

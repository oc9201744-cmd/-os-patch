#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <string.h>
#import <sys/time.h>
#import <time.h>
#import <sys/mman.h>
#import <libkern/OSCacheControl.h>
#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import <UIKit/UIKit.h>

#pragma mark - STEALTH INLINE HOOK ENGINE (Anti-Integrity Check)

#if __arm64__ || __aarch64__

// Hafıza izinlerini değiştirmek için güvenli fonksiyon
static int SetMemoryProtection(void *addr, size_t size, int protection) {
    mach_port_t task = mach_task_self();
    vm_address_t page = (vm_address_t)addr & ~(vm_address_t)(0x4000 - 1);
    vm_address_t end_page = ((vm_address_t)addr + size + 0x4000 - 1) & ~(vm_address_t)(0x4000 - 1);
    vm_size_t page_size = end_page - page;

    kern_return_t kr = vm_protect(task, page, page_size, false, protection);
    return (kr == KERN_SUCCESS) ? 0 : -1;
}

// Trambolin oluştururken RWX yerine önce RW sonra RX yapıyoruz (Bu banı engeller)
static void *CreateStealthTrampoline(void *target) {
    // 1. Sayfayı oluştur (Sadece RW)
    void *trampoline = mmap(NULL, 0x4000, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_JIT, -1, 0);
    if (trampoline == MAP_FAILED) return NULL;

    // 2. Orijinal kodları kopyala
    uint32_t origInstructions[4];
    memcpy(origInstructions, target, 16);

    uint8_t *p = (uint8_t *)trampoline;
    memcpy(p, origInstructions, 16);
    p += 16;

    // 3. Geri dönüş adresini hesapla
    uintptr_t resumeAddr = (uintptr_t)target + 16;

    // 4. Atla (Branch) kodlarını yaz
    uint32_t ldr_x16 = 0x58000050;
    uint32_t br_x16 = 0xD61F0200;
    memcpy(p, &ldr_x16, 4); p += 4;
    memcpy(p, &br_x16, 4); p += 4;
    memcpy(p, &resumeAddr, 8);

    // 5. KRİTİK ADIM: Sayfayı RX (Read-Execute) yap. RWX bırakırsan ban yersin!
    mprotect(trampoline, 0x4000, PROT_READ | PROT_EXEC);
    sys_icache_invalidate(trampoline, 0x4000);

    return trampoline;
}

static int StealthHook(void *target, void *replacement, void **origOut) {
    if (!target || !replacement) return -1;

    if (origOut) {
        void *trampoline = CreateStealthTrampoline(target);
        if (!trampoline) return -1;
        *origOut = trampoline;
    }

    uint8_t hookCode[16];
    uint32_t ldr_x16 = 0x58000050;
    uint32_t br_x16 = 0xD61F0200;
    uintptr_t addr = (uintptr_t)replacement;

    memcpy(hookCode, &ldr_x16, 4);
    memcpy(hookCode + 4, &br_x16, 4);
    memcpy(hookCode + 8, &addr, 8);

    // Hedef adresi yazılabilir yap (RW)
    SetMemoryProtection(target, 16, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    
    // Kodu yaz
    memcpy(target, hookCode, 16);
    
    // Hedef adresi tekrar sadece çalıştırılabilir yap (RX) -> Bütünlük Kontrolü Buraya Bakar!
    SetMemoryProtection(target, 16, VM_PROT_READ | VM_PROT_EXECUTE);
    sys_icache_invalidate(target, 16);

    return 0;
}

#endif

#pragma mark - POINTERS & LOGIC

static uintptr_t getBaseAddress(const char *imageName) {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, imageName)) {
            return (uintptr_t)_dyld_get_image_header(i);
        }
    }
    return 0;
}

// --- UI ---
void show_integrity_label() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        if (!win) win = [UIApplication sharedApplication].windows.firstObject;
        if (win && ![win viewWithTag:999]) {
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, win.frame.size.width, 25)];
            lbl.text = @"🛡️ ONUR CAN: STEALTH INTEGRITY FIX ✅";
            lbl.textColor = [UIColor greenColor];
            lbl.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.font = [UIFont boldSystemFontOfSize:11];
            lbl.tag = 999;
            [win addSubview:lbl];
        }
    });
}

// --- OFFSET HOOKS (Sadece AnoSDK) ---
// Sistem fonksiyonlarına (memcpy, gettimeofday) hook atmıyoruz çünkü bütünlüğü bozan onlar.

static void (*orig_AnoSDKDelReportData3)(void *arg);
static void hook_AnoSDKDelReportData3(void *arg) { return; }

static void *(*orig_AnoSDKGetReportData3)(void);
static void *hook_AnoSDKGetReportData3(void) { return NULL; }

static void (*orig_AnoSDKDelReportData4)(void *arg);
static void hook_AnoSDKDelReportData4(void *arg) { return; }

static void *(*orig_AnoSDKGetReportData4)(int arg);
static void *hook_AnoSDKGetReportData4(int arg) { return NULL; }

static void (*orig_sub_4A130)(void);
static void hook_sub_4A130(void) { return; }

static void (*orig_sub_E6FDC)(void *arg0, void *arg1, void *arg2);
static void hook_sub_E6FDC(void *arg0, void *arg1, void *arg2) { return; }

// --- INSTALLER ---

static void installSafeHooks(uintptr_t base) {
    // Sadece oyunun kendi fonksiyonlarını kancalıyoruz.
    // Sistem fonksiyonlarına dokunmuyoruz (Anti-Ban).
    StealthHook((void *)(base + 0xF117C), (void *)hook_AnoSDKDelReportData3, (void **)&orig_AnoSDKDelReportData3);
    StealthHook((void *)(base + 0xF1178), (void *)hook_AnoSDKGetReportData3, (void **)&orig_AnoSDKGetReportData3);
    StealthHook((void *)(base + 0xF1184), (void *)hook_AnoSDKDelReportData4, (void **)&orig_AnoSDKDelReportData4);
    StealthHook((void *)(base + 0xF1180), (void *)hook_AnoSDKGetReportData4, (void **)&orig_AnoSDKGetReportData4);
    StealthHook((void *)(base + 0x4A130), (void *)hook_sub_4A130, (void **)&orig_sub_4A130);
    StealthHook((void *)(base + 0xE6FDC), (void *)hook_sub_E6FDC, (void **)&orig_sub_E6FDC);
}

// --- CONSTRUCTOR ---

__attribute__((constructor))
static void initialize() {
    // 35 Saniye Bekle (Bütünlük Taraması Tamamen Bitsin)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        const char *targetLib = "anogs";
        uintptr_t base = getBaseAddress(targetLib);

        if (base) {
            installSafeHooks(base);
            show_integrity_label();
        } else {
            // Eğer anogs bulunamazsa 5 saniye daha dene
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                 uintptr_t retryBase = getBaseAddress(targetLib);
                 if (retryBase) {
                     installSafeHooks(retryBase);
                     show_integrity_label();
                 }
             });
        }
    });
}

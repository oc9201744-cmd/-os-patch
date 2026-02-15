#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <mach-o/dyld.h>
#include <mach/mach.h>
#include <dlfcn.h>

// --- INTERPOSE SİSTEMİ ---
typedef struct interpose_substitution {
    const void* replacement;
    const void* original;
} interpose_substitution_t;

#define INTERPOSE_FUNCTION(replacement, original) \
    __attribute__((used)) static const interpose_substitution_t interpose_##replacement \
    __attribute__((section("__DATA,__interpose"))) = { (const void*)(unsigned long)&replacement, (const void*)(unsigned long)&original }

// --- SİSTEM HOOKLARI ---
extern "C" int ptrace(int request, int pid, void* addr, int data);
int h_ptrace(int request, int pid, void* addr, int data) { return 0; }
INTERPOSE_FUNCTION(h_ptrace, ptrace);

// --- HARD MEMORY PATCH FONKSİYONU ---
// Bu fonksiyon mprotect yerine daha derinden (Mach API) zorlar.
bool patch_memory(uintptr_t address, uint32_t data) {
    kern_return_t kr;
    mach_port_t self = mach_task_self();
    
    // Sayfa korumasını kaldır (Read/Write/Execute zorlaması)
    kr = vm_protect(self, (vm_address_t)address & ~PAGE_MASK, PAGE_SIZE, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (kr != KERN_SUCCESS) return false;

    // Veriyi yaz
    *(uint32_t *)address = data;

    // Korumayı geri yükle (Read/Execute)
    vm_protect(self, (vm_address_t)address & ~PAGE_MASK, PAGE_SIZE, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    return true;
}

void apply_onur_can_patches() {
    uintptr_t base = (uintptr_t)_dyld_get_image_header(0); // Ana modül base
    
    // 1. Raporlayıcı (F012C) -> RET
    if(patch_memory(base + 0xF012C, 0xD65F03C0)) NSLog(@"[XO] F012C Patched!");

    // 2. Syscall Watcher (F838C) -> RET
    if(patch_memory(base + 0xF838C, 0xD65F03C0)) NSLog(@"[XO] F838C Patched!");

    // 3. Case 35 (11D85C) -> MOV X0, #1
    if(patch_memory(base + 0x11D85C, 0xD2800020)) {
        patch_memory(base + 0x11D860, 0xD65F03C0); // Hemen yanına RET
        NSLog(@"[XO] 11D85C Patched!");
    }
}

// --- ONUR CAN UI ---
void show_ui() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (window) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, window.frame.size.width, 30)];
            label.text = @"🛡️ Security Onur Can - PATCHED";
            label.textColor = [UIColor whiteColor];
            label.backgroundColor = [UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:0.8];
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont boldSystemFontOfSize:13];
            [window addSubview:label];
        }
    });
}

// --- BAŞLATICI ---
__attribute__((constructor))
static void init() {
    // 40 saniye bekle (Oyunun kodları şifrelemeden belleğe açması için süre lazım)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(40 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        apply_onur_can_patches();
        show_ui();
    });
}
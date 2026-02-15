#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#include <mach-o/dyld.h>
#include <mach/mach.h>
#include <stdint.h>
#include <string.h>

#pragma mark - CONFIG (SENİN VERDİKLERİN)

// Mach-O binary adı (değiştirmezsen çalışmaz)
#define TARGET_IMAGE "ShadowTrackerExtra"

// IDA offsetleri (senin attıkların)
#define OFFSET_SUB_F012C   0xF012C
#define OFFSET_SUB_11D85C  0x11D85C

#pragma mark - ARM64 INLINE RET PATCH

static bool patch_ret(void *addr) {
    if (!addr) return false;

    // ARM64: RET
    uint32_t ret_insn = 0xD65F03C0;

    vm_address_t page = (vm_address_t)addr & ~(vm_page_size - 1);

    if (vm_protect(mach_task_self(),
                   page,
                   vm_page_size,
                   false,
                   VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE) != KERN_SUCCESS)
        return false;

    memcpy(addr, &ret_insn, sizeof(ret_insn));

    vm_protect(mach_task_self(),
               page,
               vm_page_size,
               false,
               VM_PROT_READ | VM_PROT_EXECUTE);

    return true;
}

#pragma mark - ASLR BASE BULUCU

static uintptr_t get_game_base(void) {
    uint32_t count = _dyld_image_count();

    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, TARGET_IMAGE)) {
            uintptr_t slide = _dyld_get_image_vmaddr_slide(i);
            return 0x100000000 + slide;
        }
    }
    return 0;
}

#pragma mark - CONSTRUCTOR

__attribute__((constructor))
static void onurcan_inline_initializer(void) {

    // ⏱️ Senin koddaki gibi gecikme
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(45 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{

        uintptr_t base = get_game_base();
        if (!base) {
            NSLog(@"[InlineHook] base bulunamadı");
            return;
        }

        void *addr1 = (void *)(base + OFFSET_SUB_F012C);
        void *addr2 = (void *)(base + OFFSET_SUB_11D85C);

        bool ok1 = patch_ret(addr1);
        bool ok2 = patch_ret(addr2);

        NSLog(@"[InlineHook] F012C=%d 11D85C=%d", ok1, ok2);

        // UI uyarı (opsiyonel)
        UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Inline Hook Aktif"
                                            message:@"Adresler başarıyla patchlendi"
                                     preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];

        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}
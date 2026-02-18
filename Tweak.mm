#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <mach/vm_map.h>
#import <dlfcn.h>

// Bellek yazma fonksiyonu (Sideload için optimize edildi)
BOOL safe_patch(uintptr_t addr, uint32_t data) {
    mach_port_t task = mach_task_self();
    
    // Sayfa hizalaması (Alignment)
    vm_address_t page_start = trunc_page(addr);
    vm_size_t page_size = vm_kernel_page_size;

    // Yazma izni koparalım
    kern_return_t kr = vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    
    if (kr != KERN_SUCCESS) {
        return NO;
    }

    // Veriyi yaz
    *(uint32_t *)addr = data;

    // İzni geri al (Execute ve Read)
    vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    return YES;
}

static void on_image_load(const struct mach_header *mh, intptr_t slide) {
    // Framework'ün adını burada kontrol ediyoruz (Anogs.framework/Anogs gibi gelir)
    const char *path = dyld_image_path_containing_address(mh);
    if (path && (strstr(path, "Anogs.framework") || strstr(path, "Anogs"))) {
        
        // Senin verdiğin offset
        uintptr_t target_addr = slide + 0x201488; 

        // Adresteki instruction'ı kontrol edip patch'le (CSEL -> MOV W20, #0)
        if (safe_patch(target_addr, 0x52800014)) {
            NSLog(@"[Baybars] Anogs Framework basariyla patchlendi!");
        } else {
            NSLog(@"[Baybars] Yazma izni alınamadı (Sandbox engeli)!");
        }
    }
}

__attribute__((constructor))
static void init() {
    _dyld_register_func_for_add_image(&on_image_load);
}

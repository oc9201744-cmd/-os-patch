#include "patch.h"
#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <string.h>

bool patch_ret_at_address(void *addr) {
    if (!addr) return false;

    // ARM64 RET Opcode
    uint32_t ret_insn = 0xD65F03C0;
    vm_address_t page = (vm_address_t)addr & ~(vm_page_size - 1);

    // iOS/ARM64 için sayfayı yazılabilir yap (VM_PROT_COPY zorunludur)
    kern_return_t kr = vm_protect(mach_task_self(), page, vm_page_size, false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (kr != KERN_SUCCESS) return false;

    // Yamayı uygula
    memcpy(addr, &ret_insn, sizeof(ret_insn));

    // Sayfayı eski güvenli haline döndür
    vm_protect(mach_task_self(), page, vm_page_size, false, VM_PROT_READ | VM_PROT_EXECUTE);

    return true;
}

uintptr_t get_image_base(const char *image_name) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, image_name)) {
            return (uintptr_t)_dyld_get_image_vmaddr_slide(i) + 0x100000000;
        }
    }
    return 0;
}

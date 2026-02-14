#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>
#include <mach/mach.h>

uintptr_t get_slide() {
    return _dyld_get_image_vmaddr_slide(0);
}

void patch_memory(uintptr_t offset, unsigned char* patch, size_t size) {
    uintptr_t addr = get_slide() + offset;
    mach_port_t task = mach_task_self();
    vm_protect(task, addr, size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    vm_write(task, addr, (vm_offset_t)patch, (mach_msg_type_number_t)size);
    vm_protect(task, addr, size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
}

void apply_patches() {
    unsigned char ret[] = {0xC0, 0x03, 0x5F, 0xD6};
    uint32_t zero = 0;
    
    patch_memory(0x23998C, ret, 4);
    patch_memory(0x202B5C, ret, 4);
    patch_memory(0x2030FC, ret, 4);
    patch_memory(0x17F4C,  ret, 4);
    patch_memory(0xF838C,  ret, 4);
    
    patch_memory(0x30,  (unsigned char*)&zero, 4);
    patch_memory(0x178, (unsigned char*)&zero, 4);
    patch_memory(0x376, (unsigned char*)&zero, 1);
}

__attribute__((constructor))
void _init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        apply_patches();
    });
}

#import <mach/mach_init.h>
#import <mach/vm_map.h>

void patch_function(void* address, uint32_t new_instruction) {
    vm_protect(mach_task_self(), (vm_address_t)address, sizeof(uint32_t), 0, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE);
    *(uint32_t*)address = new_instruction;
    vm_protect(mach_task_self(), (vm_address_t)address, sizeof(uint32_t), 0, VM_PROT_EXECUTE);
}

// Kullanım:
// ARM64: mov x0, #0; ret  (gerçek opcode'ları bulmalısın)

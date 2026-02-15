#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <sys/mman.h>
#include <string.h>

// Hafızaya güvenli byte yazma fonksiyonu
void patch_offset(uintptr_t absolute_address, const unsigned char *bytes, size_t size) {
    uintptr_t page_start = absolute_address & ~PAGE_MASK;
    
    // 1. Sayfayı yazılabilir yap (RWX)
    mprotect((void *)page_start, PAGE_SIZE, PROT_READ | PROT_WRITE | PROT_EXEC);
    
    // 2. Byte'ları kopyala
    memcpy((void *)absolute_address, bytes, size);
    
    // 3. Sayfayı orijinal haline getir (RX)
    mprotect((void *)page_start, PAGE_SIZE, PROT_READ | PROT_EXEC);
}

// ARM64 Komut Seti Sabitleri
const unsigned char arm64_ret[] = {0xC0, 0x03, 0x5F, 0xD6}; // ret
const unsigned char arm64_mov_w0_0_ret[] = {0x00, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6}; // mov w0, #0; ret
const unsigned char arm64_mov_w0_1_ret[] = {0x20, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6}; // mov w0, #1; ret

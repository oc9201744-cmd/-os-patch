#include <mach-o/dyld.h>
#include <mach/mach.h>
#include <sys/mman.h>
#include <string.h>

// 1. Canlı Base Adresini (ASLR dahil) otomatik bulur
uintptr_t get_live_base() {
    // 0. index her zaman ana uygulamanın (executable) header'ıdır
    return (uintptr_t)_dyld_get_image_header(0);
}

// 2. Güvenli Yazma (iOS 17 & iPhone 15 Pro Max Uyumlu)
bool auto_patch(uintptr_t offset, const void *data, size_t size) {
    uintptr_t address = get_live_base() + offset;
    
    // iPhone 15 Pro Max için 16KB Sayfa Hizalaması
    size_t pageSize = PAGE_SIZE; 
    uintptr_t pageStart = address & ~(pageSize - 1);
    
    // Yazma İzni Al (PROT_COPY iOS 17'de daha stabildir)
    if (mprotect((void *)pageStart, pageSize, PROT_READ | PROT_WRITE | PROT_COPY) != 0) {
        mprotect((void *)pageStart, pageSize, PROT_READ | PROT_WRITE | PROT_EXEC);
    }
    
    // Yamayı uygula
    memcpy((void *)address, data, size);
    
    // Korumayı geri yükle
    mprotect((void *)pageStart, pageSize, PROT_READ | PROT_EXEC);
    return true;
}

// ARM64 Sabitleri
const unsigned char arm64_ret[] = {0xC0, 0x03, 0x5F, 0xD6};
const unsigned char arm64_mov_w0_0_ret[] = {0x00, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6};
const unsigned char arm64_mov_w0_1_ret[] = {0x20, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6};

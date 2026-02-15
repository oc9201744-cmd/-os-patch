#ifndef MEMORY_UTILS_H
#define MEMORY_UTILS_H

#include <mach-o/dyld.h>
#include <mach/mach.h>
#include <sys/mman.h>
#include <string.h>

// iOS SDK'da PROT_COPY bazen eksik olabilir, manuel tanımlıyoruz
#ifndef PROT_COPY
#define PROT_COPY 0x10
#endif

// Canlı Base Adresini (ASLR dahil) otomatik bulur
static uintptr_t get_live_base() {
    return (uintptr_t)_dyld_get_image_header(0);
}

// Güvenli Yazma (iPhone 15 Pro Max & iOS 17/18 Uyumlu)
static bool auto_patch(uintptr_t offset, const void *data, size_t size) {
    uintptr_t address = get_live_base() + offset;
    
    // Sayfa Hizalaması
    size_t pageSize = PAGE_SIZE; 
    uintptr_t pageStart = address & ~(pageSize - 1);
    
    // Yazma İzni Al: PROT_COPY | PROT_READ | PROT_WRITE
    if (mprotect((void *)pageStart, pageSize, PROT_READ | PROT_WRITE | PROT_COPY) != 0) {
        // Eğer PROT_COPY başarısız olursa standart RWX dene
        mprotect((void *)pageStart, pageSize, PROT_READ | PROT_WRITE | PROT_EXEC);
    }
    
    // Yamayı uygula
    memcpy((void *)address, data, size);
    
    // Korumayı geri yükle (Sadece Okuma ve Çalıştırma)
    mprotect((void *)pageStart, pageSize, PROT_READ | PROT_EXEC);
    return true;
}

// ARM64 Komutları
const unsigned char arm64_ret[] = {0xC0, 0x03, 0x5F, 0xD6};
const unsigned char arm64_mov_w0_0_ret[] = {0x00, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6};
const unsigned char arm64_mov_w0_1_ret[] = {0x20, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6};

#endif

void setup_bypass() {
    // Ofsetimiz (IDA'da 1000F838C -> F838C)
    uintptr_t offset = 0xF838C; 
    
    // HATA BURADAYDI: (uintptr_t) ekleyerek tipi zorla dönüştürüyoruz
    uintptr_t base = (uintptr_t)_dyld_get_image_header(0);
    
    uintptr_t target_address = base + offset;

    // 0xD65F03C0 = ARM64 'RET' komutu
    patch_memory(target_address, 0xD65F03C0);
}

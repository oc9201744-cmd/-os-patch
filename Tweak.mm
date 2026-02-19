#import <dobby.h>

// Örnek: Ana kontrol fonksiyonunu (0xD372C) etkisiz bırakma
void (*old_D372C)(void);
void new_D372C(void) {
    // Fonksiyonun hiçbir şey yapmadan dönmesini sağlıyoruz (void dönüşlü ise)
    // Eğer bool dönüyorsa 'return true' veya 'return false' denenebilir.
    return;
}

// Tweak yüklendiğinde çalışacak kısım
%ctor {
    uintptr_t base = (uintptr_t)_dyld_get_image_header(0); // Framework base adresini bulur
    
    // Offsetleri base adrese ekleyerek hookluyoruz
    DobbyHook((void *)(base + 0xD372C), (void *)new_D372C, (void **)&old_D372C);
    
    // Jailbreak kontrolünü (0x49F24) 'temiz' gösterme
    DobbyHook((void *)(base + 0x49F24), (void *)new_D372C, NULL); 
}

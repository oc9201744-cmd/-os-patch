#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#include <stdint.h>
#include <string.h>

// Bu fonksiyon yeni bir kütüphane yüklendiğinde çalışır
static void image_added(const struct mach_header *mh, intptr_t vmaddr_slide) {
    // Tüm yüklü imajları tarayarak ismini buluyoruz
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        // Header adresi bizim yakaladığımız ile eşleşiyor mu?
        if (_dyld_get_image_header(i) == mh) {
            const char *name = _dyld_get_image_name(i);
            
            // Sadece anogs içerenleri logla
            if (name && strstr(name, "anogs")) {
                NSLog(@"\n\n[ACE_LOG] =================================");
                NSLog(@"[ACE_LOG] 🔥 ANOGS BELLEĞE YÜKLENDİ!");
                NSLog(@"[ACE_LOG] 📍 Yol: %s", name);
                NSLog(@"[ACE_LOG] 🚀 ASLR Slide: 0x%lx", (long)vmaddr_slide);
                NSLog(@"[ACE_LOG] 🎯 Header: %p", mh);
                NSLog(@"[ACE_LOG] =================================\n\n");
            }
            break;
        }
    }
}

__attribute__((constructor))
static void init_logging(void) {
    NSLog(@"[ACE_LOG] Takip başlatıldı, Anogs bekleniyor...");
    
    // Sistemdeki dylib yüklemelerini izlemek için en sağlam yöntem
    _dyld_register_func_for_add_image(image_added);
}

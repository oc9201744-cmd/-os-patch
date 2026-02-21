#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#include <stdint.h>
#include <string.h>

// Bu fonksiyon Anogs modülü belleğe girdiği an sistem tarafından tetiklenir
static void on_anogs_load(const struct mach_header *mh, intptr_t slide) {
    // Yüklenen kütüphanenin ismini çekiyoruz
    const char *name = _dyld_get_image_name_by_header(mh);
    
    // Sadece isminde "anogs" geçenleri yakala
    if (name && strstr(name, "anogs")) {
        NSLog(@"\n\n[ACE_LOG] =================================");
        NSLog(@"[ACE_LOG] 🔥 ANOGS BELLEĞE YÜKLENDİ!");
        NSLog(@"[ACE_LOG] 📍 Yol: %s", name);
        NSLog(@"[ACE_LOG] 🚀 ASLR Slide: 0x%lx", (long)slide);
        NSLog(@"[ACE_LOG] 🎯 Header: %p", mh);
        NSLog(@"[ACE_LOG] =================================\n\n");
    }
}

__attribute__((constructor))
static void start_monitoring(void) {
    // Cihazın genel loglarına dylib'in çalıştığını bildir
    NSLog(@"[ACE_LOG] Takip başladı, Anogs yüklenmesi bekleniyor...");
    
    // Sistemdeki tüm dylib yüklemelerini izlemeye al
    _dyld_register_func_for_add_image(on_anogs_load);
}

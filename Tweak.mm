#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#include <string.h>
#include "dobby.h" 

#define LOG(fmt, ...) NSLog(@"[AnogsBypass] " fmt, ##__VA_ARGS__)

typedef void (*orig_sub_D372C_type)(void *arg0, ...);
orig_sub_D372C_type orig_sub_D372C = NULL;

void my_sub_D372C(void *arg0) {
    LOG(@"Anogs Kontrolü Engellendi (0xD372C)");
}

__attribute__((constructor))
static void init() {
    LOG("Bypass motoru tetiklendi...");
    
    uintptr_t base = 0;
    const char *target_name = "Anogs.framework/Anogs"; 
    
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, target_name)) {
            base = (uintptr_t)_dyld_get_image_vmaddr_slide(i);
            LOG("Anogs bulundu! Base Slide: 0x%lx", base);
            break;
        }
    }
    
    if (base != 0) {
        void *target_addr = (void *)(base + 0xD372C);
        DobbyHook(target_addr, (void *)my_sub_D372C, (void **)&orig_sub_D372C);
    }
}

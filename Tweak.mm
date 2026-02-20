#include <sys/types.h>
#include <stdio.h>
#include <string.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>

// Dobby'yi sistem kütüphanelerinden SONRA dahil et
#include <dobby.h> 

// --- Geri kalan bypass kodun ---
void (*orig_11824)(void *a1, void *a2);
void hook_11824(void *a1, void *a2) { return; }

void (*orig_63D4)(void *a1);
void hook_63D4(void *a1) { return; }

uintptr_t get_anogs_base() {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *image_name = _dyld_get_image_name(i);
        if (image_name && strstr(image_name, "anogs")) {
            return (uintptr_t)_dyld_get_image_header(i);
        }
    }
    return 0;
}

__attribute__((constructor))
static void init() {
    uintptr_t base = get_anogs_base();
    if (base != 0) {
        DobbyHook((void*)(base + 0x11824), (void*)hook_11824, (void**)&orig_11824);
        DobbyHook((void*)(base + 0x63D4), (void*)hook_63D4, (void**)&orig_63D4);
    }
}

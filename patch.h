#ifndef PATCH_H
#define PATCH_H

#include <stdint.h>
#include <stdbool.h>

// ARM64 RET Patch fonksiyonu
bool patch_ret_at_address(void *addr);

// ASLR Base bulucu
uintptr_t get_image_base(const char *image_name);

#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <dlfcn.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <dirent.h>
#include <pthread.h>
#include <mach/mach.h>
#include <mach/vm_map.h>
#include <mach-o/dyld.h>
#include <libkern/OSCacheControl.h>

// ============================================================
// DOBBY INLINE MOTORU (Senin Orijinal Yapın)
// ============================================================
typedef struct {
    void* target;
    void* replacement;
    void** original;
    uint8_t backup[16];
    void* trampoline;
} HookEntry;

#define MAX_HOOKS 128
static HookEntry g_hooks[MAX_HOOKS];
static int g_hook_count = 0;
static pthread_mutex_t g_hook_mutex = PTHREAD_MUTEX_INITIALIZER;

static void emit_arm64_branch(void* from, void* to) {
    uint32_t* code = (uint32_t*)from;
    code[0] = 0x58000050; // LDR X16, [PC, #8]
    code[1] = 0xD61F0200; // BR X16
    *(uint64_t*)&code[2] = (uint64_t)to;
}

static bool set_mem_permission(void* addr, size_t size, int prot) {
    uintptr_t page = (uintptr_t)addr & ~(0x4000 - 1);
    size_t len = (uintptr_t)addr - page + size;
    len = (len + 0x3FFF) & ~0x3FFF;
    kern_return_t kr = vm_protect(mach_task_self(), (vm_address_t)page, (vm_size_t)len, false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    return kr == KERN_SUCCESS;
}

static void* create_trampoline(void* target, size_t backup_size) {
    void* tramp = mmap(NULL, 0x4000, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_PRIVATE | MAP_ANONYMOUS | MAP_JIT, -1, 0);
    if (tramp == MAP_FAILED) return NULL;
    memcpy(tramp, target, backup_size);
    emit_arm64_branch((uint8_t*)tramp + backup_size, (uint8_t*)target + backup_size);
    sys_icache_invalidate(tramp, 0x4000);
    return tramp;
}

static int DobbyHook(void* target, void* replacement, void** p_original) {
    pthread_mutex_lock(&g_hook_mutex);
    if (g_hook_count >= MAX_HOOKS || !target) { pthread_mutex_unlock(&g_hook_mutex); return -1; }
    HookEntry* entry = &g_hooks[g_hook_count];
    entry->target = target;
    entry->replacement = replacement;
    entry->original = p_original;
    memcpy(entry->backup, target, 16);
    void* tramp = create_trampoline(target, 16);
    if (!tramp) { pthread_mutex_unlock(&g_hook_mutex); return -2; }
    entry->trampoline = tramp;
    if (p_original) *p_original = tramp;
    if (!set_mem_permission(target, 16, VM_PROT_ALL)) { pthread_mutex_unlock(&g_hook_mutex); return -3; }
    emit_arm64_branch(target, replacement);
    sys_icache_invalidate(target, 16);
    g_hook_count++;
    pthread_mutex_unlock(&g_hook_mutex);
    return 0;
}

// ============================================================
// TSS / ACE ANALİZİNDEN GELEN ÖZEL HOOKLAR
// ============================================================

static uintptr_t tss_base = 0;
uintptr_t get_tss_base(void) {
    if (tss_base) return tss_base;
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char* name = _dyld_get_image_name(i);
        if (name && (strstr(name, "tersafe") || strstr(name, "AntiCheat") || strstr(name, "libtprt"))) {
            tss_base = (uintptr_t)_dyld_get_image_header(i);
            return tss_base;
        }
    }
    return 0;
}

// 1. ACE Modül Başlatıcı (0xF012C) - Banı baştan keser
long long (*orig_sub_F012C)(void *a1);
long long hook_sub_F012C(void *a1) { return 0; } 

// 2. Sistem Dağıtıcısı (0xF838C) - Crash engelleyici passthrough
void* (*orig_sub_F838C)(void *a1, void *a2, unsigned long a3, void *a4);
void* hook_sub_F838C(void *a1, void *a2, unsigned long a3, void *a4) {
    return orig_sub_F838C(a1, a2, a3, a4);
}

// 3. Root Alert Raporlayıcı (0x7A19C)
void* (*orig_root_alert)(void*, const char*, uint8_t*, int);
void* hook_root_alert(void* a1, const char* tag, uint8_t* data, int flag) {
    if (tag && strstr(tag, "root_alert")) return NULL;
    return orig_root_alert(a1, tag, data, flag);
}

// 4. Konfigürasyon Şalterleri (nullsub_179 mevkii)
int64_t (*orig_config_reader)(void*, const char*, int64_t, int64_t);
int64_t hook_config_reader(void* a1, const char* key, int64_t a3, int64_t a4) {
    if (key) {
        if (strcmp(key, "cs_speed_ctl") == 0) return 0;
        if (strcmp(key, "tdm_report") == 0) return 0;
        if (strcmp(key, "shell_report") == 0) return 0;
    }
    return orig_config_reader(a1, key, a3, a4);
}

// 5. Bütünlük Yaması (0xD3844) - Manuel NOP
void apply_integrity_patch(uintptr_t base) {
    uint32_t nop = 0xD503201F;
    if (set_mem_permission((void *)(base + 0xD3844), 4, VM_PROT_ALL)) {
        memcpy((void *)(base + 0xD3844), &nop, 4);
        sys_icache_invalidate((void *)(base + 0xD3844), 4);
    }
}

// ============================================================
// GENEL JAYBREAK VE GİZLEME HOOKLARI
// ============================================================

static FILE* (*orig_fopen)(const char*, const char*);
FILE* hook_fopen(const char* path, const char* mode) {
    if (path && (strstr(path, "/Cydia") || strstr(path, "/jb") || strstr(path, "Substrate"))) return NULL;
    return orig_fopen(path, mode);
}

static uint32_t (*orig_dyld_image_count)(void);
uint32_t hook_dyld_image_count(void) {
    return orig_dyld_image_count() - 1; // Kendimizi gizleyelim
}

// ============================================================
// ANA BAŞLATICI (Constructor)
// ============================================================

__attribute__((constructor))
static void dooby_master_init(void) {
    // Önce sistem libc hookları
    DobbyHook((void*)fopen, (void*)hook_fopen, (void**)&orig_fopen);
    DobbyHook((void*)_dyld_image_count, (void*)hook_dyld_image_count, (void**)&orig_dyld_image_count);

    // TSS/ACE Modülü yüklendi mi bak
    uintptr_t base = get_tss_base();
    if (base) {
        // Analiz ettiğimiz ofsetler
        DobbyHook((void*)(base + 0xF012C), (void*)hook_sub_F012C, (void**)&orig_sub_F012C);
        DobbyHook((void*)(base + 0xF838C), (void*)hook_sub_F838C, (void**)&orig_sub_F838C);
        DobbyHook((void*)(base + 0x7A19C), (void*)hook_root_alert, (void**)&orig_root_alert);
        
        // Bütünlük yamasını uygula
        apply_integrity_patch(base);
    }
}

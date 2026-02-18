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
// 1. GÖMÜLÜ DOBBY MOTORU (ARM64 INLINE HOOK)
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
// 2. MODÜL BULUCU VE YARDIMCI ARAÇLAR
// ============================================================

static uintptr_t tss_base = 0;
uintptr_t get_tss_base(void) {
    if (tss_base) return tss_base;
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char* name = _dyld_get_image_name(i);
        if (name && (strstr(name, "tersafe") || strstr(name, "AntiCheat") || strstr(name, "libtprt") || strstr(name, "tss"))) {
            tss_base = (uintptr_t)_dyld_get_image_header(i);
            return tss_base;
        }
    }
    return 0;
}

#define TSS_ADDR(offset) ((void*)(get_tss_base() + (offset)))

// ============================================================
// 3. TSS / ACE ÖZEL BAN BYPASSLARI (OFSET TABANLI)
// ============================================================

// --- 0xF012C: ACE_EXPORT Başlatıcı (bak 4.txt) ---
long long (*orig_sub_F012C)(void *a1);
long long hook_sub_F012C(void *a1) {
    // Bu fonksiyon sürüm raporu ve PID kaydı yapar. Susturuyoruz.
    return 0; 
}

// --- 0xF838C: Sistem Dağıtıcısı (bak 6.txt) ---
void* (*orig_sub_F838C)(void *a1, void *a2, unsigned long a3, void *a4);
void* hook_sub_F838C(void *a1, void *a2, unsigned long a3, void *a4) {
    // mmap ve syscall yönetimi yapar. Orijinali çağrılmazsa oyun çöker.
    return orig_sub_F838C(a1, a2, a3, a4);
}

// --- 0x7A19C: root_alert Reporter ---
void* (*orig_sub_7A19C)(void* a1, const char* tag, uint8_t* data, int flag);
void* hook_sub_7A19C(void* a1, const char* tag, uint8_t* data, int flag) {
    if (tag && strstr(tag, "root_alert")) return NULL; // Raporu engelle
    return orig_sub_7A19C(a1, tag, data, flag);
}

// --- 0x175E8: Rapor Metni Oluşturucu ---
void (*orig_sub_175E8)(uint64_t buf, int64_t str);
void hook_sub_175E8(uint64_t buf, int64_t str) {
    const char* s = (const char*)str;
    if (s && (strstr(s, "emulator_name") || strstr(s, "root_alert"))) return;
    orig_sub_175E8(buf, str);
}

// --- 0x175B8: hash2 Bütünlük Kontrolü ---
int (*orig_sub_175B8)(const char* key, void* data, int64_t len);
int hook_sub_175B8(const char* key, void* data, int64_t len) {
    if (key && strcmp(key, "hash2") == 0) return 0; // Hep geçerli say
    return orig_sub_175B8(key, data, len);
}

// --- 0xD3844: Kod Bütünlüğü Yaması (NOP) ---
void apply_integrity_patch(uintptr_t base) {
    uint32_t nop_inst = 0xD503201F;
    if (set_mem_permission((void *)(base + 0xD3844), 4, VM_PROT_ALL)) {
        memcpy((void *)(base + 0xD3844), &nop_inst, 4);
        sys_icache_invalidate((void *)(base + 0xD3844), 4);
    }
}

// ============================================================
// 4. GENEL SİSTEM (LIBC/DYLD) BYPASSLARI
// ============================================================

// Dosya sistemi taramasını engelle
static FILE* (*orig_fopen)(const char*, const char*);
FILE* hook_fopen(const char* path, const char* mode) {
    const char* blacklist[] = {"/Applications/Cydia", "/usr/sbin/sshd", "/bin/bash", "/Library/MobileSubstrate", "/var/jb", NULL};
    if (path) {
        for (int i = 0; blacklist[i]; i++) {
            if (strstr(path, blacklist[i])) return NULL;
        }
    }
    return orig_fopen(path, mode);
}

// Kendimizi listeden gizleyelim
static uint32_t (*orig_dyld_image_count)(void);
uint32_t hook_dyld_image_count(void) {
    return orig_dyld_image_count() - 1;
}

// ============================================================
// 5. ANA BAŞLATICI (CONSTRUCTOR)
// ============================================================

__attribute__((constructor))
static void dooby_init_all(void) {
    // 1. Sistem Seviyesi Hooklar
    DobbyHook((void*)fopen, (void*)hook_fopen, (void**)&orig_fopen);
    DobbyHook((void*)_dyld_image_count, (void*)hook_dyld_image_count, (void**)&orig_dyld_image_count);

    // 2. TSS / ACE Seviyesi Hooklar (Modül Yüklendiğinde)
    // TrollStore veya Sideload'da dylib en başta yüklenir, base'i beklememiz gerekebilir.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        uintptr_t base = get_tss_base();
        if (base) {
            // Ban Koruma Noktaları
            DobbyHook((void*)(base + 0xF012C), (void*)hook_sub_F012C, (void**)&orig_sub_F012C);
            DobbyHook((void*)(base + 0xF838C), (void*)hook_sub_F838C, (void**)&orig_sub_F838C);
            DobbyHook((void*)(base + 0x7A19C), (void*)hook_sub_7A19C, (void**)&orig_sub_7A19C);
            DobbyHook((void*)(base + 0x175E8), (void*)hook_sub_175E8, (void**)&orig_sub_175E8);
            DobbyHook((void*)(base + 0x175B8), (void*)hook_sub_175B8, (void**)&orig_sub_175B8);
            
            // Kod Yaması
            apply_integrity_patch(base);
        }
    });
}

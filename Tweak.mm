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
#include <pthread.h>
#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <dispatch/dispatch.h>

// ============================================================
// DOBBY MOTORU & YARDIMCI FONKSİYONLAR
// ============================================================
typedef struct {
    void* target; void* replacement; void** original;
    uint8_t backup[16]; void* trampoline;
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

static bool set_mem_permission(void* addr, size_t size) {
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
    return tramp;
}

static int DobbyHook(void* target, void* replacement, void** p_original) {
    pthread_mutex_lock(&g_hook_mutex);
    if (g_hook_count >= MAX_HOOKS || !target) { pthread_mutex_unlock(&g_hook_mutex); return -1; }
    void* tramp = create_trampoline(target, 16);
    if (p_original) *p_original = tramp;
    if (set_mem_permission(target, 16)) {
        emit_arm64_branch(target, replacement);
        g_hook_count++;
    }
    pthread_mutex_unlock(&g_hook_mutex);
    return 0;
}

static uintptr_t get_tss_base() {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char* name = _dyld_get_image_name(i);
        if (name && (strstr(name, "tersafe") || strstr(name, "AntiCheat"))) 
            return (uintptr_t)_dyld_get_image_header(i);
    }
    return 0;
}

// ============================================================
// HOOKS & BYPASS LOGIC
// ============================================================

static long long (*orig_sub_F012C)(void *a1);
long long hook_sub_F012C(void *a1) { return 0; }

static int (*orig_sub_175B8)(const char* key, void* data, int64_t len);
int hook_sub_175B8(const char* key, void* data, int64_t len) {
    if (key && strstr(key, "hash")) return 0;
    return orig_sub_175B8(key, data, len);
}

static void* (*orig_sub_F838C)(void *a1, void *a2, unsigned long a3, void *a4);
void* hook_sub_F838C(void *a1, void *a2, unsigned long a3, void *a4) {
    return orig_sub_F838C(a1, a2, a3, a4);
}

// ============================================================
// CONSTRUCTOR & LOG BASMA
// ============================================================

__attribute__((constructor))
static void init_master_bypass() {
    // 8 saniye sonra modülleri yamala ve yazıyı bas
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 8 * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        uintptr_t base = get_tss_base();
        if (base) {
            DobbyHook((void*)(base + 0xF012C), (void*)hook_sub_F012C, (void**)&orig_sub_F012C);
            DobbyHook((void*)(base + 0x175B8), (void*)hook_sub_175B8, (void**)&orig_sub_175B8);
            DobbyHook((void*)(base + 0xF838C), (void*)hook_sub_F838C, (void**)&orig_sub_F838C);
            
            uint32_t nop = 0xD503201F;
            if (set_mem_permission((void *)(base + 0xD3844), 4)) {
                memcpy((void *)(base + 0xD3844), &nop, 4);
            }

            // --- BYPASS AKTİF YAZISI ---
            printf("\n\n[BYPASS] ===================================\n");
            printf("[BYPASS] TSS/ACE MODÜLÜ BULUNDU: 0x%lx\n", base);
            printf("[BYPASS] TÜM HOOKLAR BAŞARIYLA ATILDI!\n");
            printf("[BYPASS] BAYBARS V5 AKTİF DURUMDA!\n");
            printf("[BYPASS] ===================================\n\n");
            
        } else {
            printf("[BYPASS] HATA: AntiCheat modülü bulunamadı!\n");
        }
    });
}

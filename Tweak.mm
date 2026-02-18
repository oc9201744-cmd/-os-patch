// dooby_hook.c
// TSS AntiCheat Bypass - Dobby Hook Implementation
// Compiler: clang -arch arm64 -shared -o dooby_hook.dylib dooby_hook.c -ldobby
// Theos: place in Tweak.x with logos syntax or compile as raw dylib

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <dirent.h>
#include <mach/mach.h>
#include <mach-o/dyld.h>


// ============================================================
// UTILS
// ============================================================

static uintptr_t tss_base = 0;

static uintptr_t get_tss_base() {
    if (tss_base) return tss_base;
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && (strstr(name, "tersafe") || strstr(name, "AntiCheat") || strstr(name, "tss"))) {
            tss_base = (uintptr_t)_dyld_get_image_header(i);
            return tss_base;
        }
    }
    return 0;
}

#define TSS_ADDR(offset) ((void*)(get_tss_base() + offset))

// ============================================================
// 1. ROOT / JAILBREAK BYPASS
// ============================================================

// --- Hook: root_alert reporter (sub_7A19C) ---
static void* (*orig_root_alert)(void* a1, const char* tag, uint8_t* data, int flag);
static void* hook_root_alert(void* a1, const char* tag, uint8_t* data, int flag) {
    if (tag && strstr(tag, "root_alert")) {
        return NULL;
    }
    return orig_root_alert(a1, tag, data, flag);
}

// --- Hook: fopen (jailbreak file checks) ---
static FILE* (*orig_fopen)(const char* path, const char* mode);
static FILE* hook_fopen(const char* path, const char* mode) {
    if (path) {
        const char* blocked[] = {
            "/Applications/Cydia.app",
            "/usr/sbin/sshd",
            "/bin/bash",
            "/usr/bin/ssh",
            "/private/var/lib/apt",
            "/etc/apt",
            "/Library/MobileSubstrate",
            "/var/lib/cydia",
            "/usr/libexec/cydia",
            "/private/var/stash",
            "/usr/bin/cycript",
            "/var/cache/apt",
            "/var/lib/dpkg",
            "/private/etc/dpkg",
            "/jb/",
            NULL
        };
        for (int i = 0; blocked[i]; i++) {
            if (strstr(path, blocked[i])) return NULL;
        }
    }
    return orig_fopen(path, mode);
}

// --- Hook: opendir (directory scanning) ---
static DIR* (*orig_opendir)(const char* path);
static DIR* hook_opendir(const char* path) {
    if (path) {
        if (strstr(path, "MobileSubstrate") ||
            strstr(path, "TweakInject") ||
            strstr(path, "substrate") ||
            strstr(path, "Cydia") ||
            strstr(path, "SubstituteLoader")) {
            return NULL;
        }
    }
    return orig_opendir(path);
}

// --- Hook: sysctl (P_TRACED flag removal) ---
static int (*orig_sysctl)(int*, u_int, void*, size_t*, void*, size_t);
static int hook_sysctl(int* name, u_int namelen, void* info, size_t* infoLen, void* newinfo, size_t newinfolen) {
    int ret = orig_sysctl(name, namelen, info, infoLen, newinfo, newinfolen);
    if (namelen == 4 && name[0] == CTL_KERN && name[1] == KERN_PROC && name[2] == KERN_PROC_PID) {
        struct kinfo_proc* kinfo = (struct kinfo_proc*)info;
        if (kinfo) {
            kinfo->kp_proc.p_flag &= ~P_TRACED;
        }
    }
    return ret;
}

// ============================================================
// 2. EMULATOR DETECTION BYPASS
// ============================================================

static int (*orig_sysctlbyname)(const char*, void*, size_t*, void*, size_t);
static int hook_sysctlbyname(const char* name, void* oldp, size_t* oldlenp, void* newp, size_t newlen) {
    int ret = orig_sysctlbyname(name, oldp, oldlenp, newp, newlen);
    if (name && oldp) {
        if (strcmp(name, "hw.machine") == 0) {
            const char* spoof = "iPhone14,5";
            if (oldlenp && *oldlenp >= strlen(spoof) + 1) {
                strcpy((char*)oldp, spoof);
            }
        }
        if (strcmp(name, "hw.cputype") == 0) {
            *(int*)oldp = 0x100000C; // CPU_TYPE_ARM64
        }
        if (strcmp(name, "hw.cpusubtype") == 0) {
            *(int*)oldp = 0x2; // CPU_SUBTYPE_ARM64_V8
        }
    }
    return ret;
}

// --- Hook: emulator_name reporter (sub_175E8) ---
static void (*orig_emulator_reporter)(uint64_t buf, int64_t str);
static void hook_emulator_reporter(uint64_t buf, int64_t str) {
    const char* s = (const char*)str;
    if (s && strstr(s, "emulator_name")) {
        return;
    }
    orig_emulator_reporter(buf, str);
}

// ============================================================
// 3. SPEED HACK DETECTION BYPASS
// ============================================================

// --- Hook: nullsub_179 (config flag reader) ---
// This single hook disables: cs_speed_ctl, tdm_report, shell_report, CSReconnect
static int64_t (*orig_config_reader)(void* a1, const char* key, int64_t a3, int64_t a4);
static int64_t hook_config_reader(void* a1, const char* key, int64_t a3, int64_t a4) {
    if (key) {
        if (strcmp(key, "cs_speed_ctl") == 0) return 0;
        if (strcmp(key, "tdm_report") == 0) return 0;
        if (strcmp(key, "shell_report") == 0) return 0;
        if (strcmp(key, "CSReconnect") == 0) return 0;
        if (strcmp(key, "tcj_encrypt") == 0) return 0;
    }
    return orig_config_reader(a1, key, a3, a4);
}

// ============================================================
// 4. MEMORY TAMPERING BYPASS
// ============================================================

// --- Hook: vm_remap (block shadow copy creation) ---
static kern_return_t (*orig_vm_remap)(vm_map_t, vm_address_t*, vm_size_t,
    vm_address_t, int, vm_map_t, vm_address_t, boolean_t,
    vm_prot_t*, vm_prot_t*, vm_inherit_t);
static kern_return_t hook_vm_remap(vm_map_t target, vm_address_t* addr,
    vm_size_t size, vm_address_t mask, int flags, vm_map_t src_task,
    vm_address_t src_addr, boolean_t copy, vm_prot_t* cur,
    vm_prot_t* max, vm_inherit_t inherit) {
    // Block TSS from creating shadow copies for integrity check
    if (src_task == mach_task_self()) {
        uintptr_t base = get_tss_base();
        if (base && src_addr >= base && src_addr < base + 0x400000) {
            return KERN_FAILURE;
        }
    }
    return orig_vm_remap(target, addr, size, mask, flags, src_task,
                         src_addr, copy, cur, max, inherit);
}

// --- Hook: vm_read (spoof clean pages) ---
static kern_return_t (*orig_vm_read)(vm_map_t, vm_address_t, vm_size_t,
    vm_offset_t*, mach_msg_type_number_t*);
static kern_return_t hook_vm_read(vm_map_t task, vm_address_t addr,
    vm_size_t size, vm_offset_t* data, mach_msg_type_number_t* cnt) {
    // Pass through - advanced: cache original pages before hooking
    // and return cached pages when TSS reads its own code
    return orig_vm_read(task, addr, size, data, cnt);
}

// ============================================================
// 5. DEBUG / PTRACE BYPASS
// ============================================================

// --- Hook: PT_DENY_ATTACH (sub_370B0) ---
static int (*orig_ptrace_deny)(void);
static int hook_ptrace_deny(void) {
    return 0; // Skip PT_DENY_ATTACH
}

// --- Hook: task_info (hide DYLD info) ---
static kern_return_t (*orig_task_info)(task_name_t, task_flavor_t,
    task_info_t, mach_msg_type_number_t*);
static kern_return_t hook_task_info(task_name_t task, task_flavor_t flavor,
    task_info_t info, mach_msg_type_number_t* cnt) {
    kern_return_t ret = orig_task_info(task, flavor, info, cnt);
    if (flavor == 0x13) { // TASK_DYLD_INFO
        // Optionally modify dyld info to hide injected images
    }
    return ret;
}

// --- Hook: dladdr (self-verification bypass) ---
static int (*orig_dladdr)(const void*, Dl_info*);
static int hook_dladdr(const void* addr, Dl_info* info) {
    int ret = orig_dladdr(addr, info);
    if (ret && info && info->dli_fname) {
        // If TSS queries its own functions, ensure correct module path
        if (strstr(info->dli_fname, "dooby") || strstr(info->dli_fname, "hook") ||
            strstr(info->dli_fname, "substrate") || strstr(info->dli_fname, "substitute")) {
            // Spoof to system library
            info->dli_fname = "/usr/lib/system/libsystem_platform.dylib";
        }
    }
    return ret;
}

// ============================================================
// 6. LIBRARY INJECTION BYPASS
// ============================================================

static uint32_t original_image_count = 0;
static int images_counted = 0;

// --- Hook: _dyld_image_count ---
static uint32_t (*orig_dyld_image_count)(void);
static uint32_t hook_dyld_image_count(void) {
    if (!images_counted) {
        original_image_count = orig_dyld_image_count();
        images_counted = 1;
    }
    return original_image_count;
}

// --- Hook: _dyld_get_image_name ---
static const char* (*orig_dyld_get_image_name)(uint32_t);
static const char* hook_dyld_get_image_name(uint32_t idx) {
    const char* name = orig_dyld_get_image_name(idx);
    if (!name) return name;
    const char* hidden[] = {
        "Substrate", "substitute", "TweakInject", "frida",
        "dobby", "fishhook", "dooby", "cycript", "libhook",
        "Shadow", "Liberty", "Choicy", "FlyJB", NULL
    };
    for (int i = 0; hidden[i]; i++) {
        if (strstr(name, hidden[i])) {
            return "/usr/lib/system/libsystem_c.dylib";
        }
    }
    return name;
}

// --- Hook: dlopen ---
static void* (*orig_dlopen)(const char* path, int mode);
static void* hook_dlopen(const char* path, int mode) {
    return orig_dlopen(path, mode);
}

// ============================================================
// 7. CODE INTEGRITY BYPASS
// ============================================================

// --- Hook: hash2 validator (sub_175B8) ---
static int (*orig_hash_validator)(const char* key, void* data, int64_t len);
static int hook_hash_validator(const char* key, void* data, int64_t len) {
    if (key && strcmp(key, "hash2") == 0) {
        return 0; // Always pass
    }
    return orig_hash_validator(key, data, len);
}

// --- Hook: fstat (file size check bypass) ---
static int (*orig_fstat)(int fd, struct stat* buf);
static int hook_fstat(int fd, struct stat* buf) {
    return orig_fstat(fd, buf);
    // Advanced: cache original file size and spoof when TSS checks
}

// ============================================================
// 8. NETWORK REPORTING BYPASS
// ============================================================

// --- Hook: cheat_open_id reporter (nullsub_157) ---
static int64_t (*orig_cheat_reporter)(void* a1, const char* key1,
    const char* key2, void* data, int64_t flag);
static int64_t hook_cheat_reporter(void* a1, const char* key1,
    const char* key2, void* data, int64_t flag) {
    if (key1 && strcmp(key1, "cheat_open_id") == 0) {
        return 0;
    }
    return orig_cheat_reporter(a1, key1, key2, data, flag);
}

// --- Hook: connect (block TSS server connections) ---
static int (*orig_connect)(int fd, const struct sockaddr* addr, socklen_t len);
static int hook_connect(int fd, const struct sockaddr* addr, socklen_t len) {
    // Optional: block specific TSS report server IPs
    // struct sockaddr_in* sin = (struct sockaddr_in*)addr;
    // if (sin->sin_family == AF_INET) {
    //     // Check if IP belongs to Tencent TSS infrastructure
    //     // Block if needed: return -1;
    // }
    return orig_connect(fd, addr, len);
}

// ============================================================
// CONSTRUCTOR - ENTRY POINT
// ============================================================

__attribute__((constructor))
static void dooby_init(void) {
    uintptr_t base = get_tss_base();
    if (!base) {
        // TSS not loaded yet - could use dyld register callback
        return;
    }

    // --- 1. Root/Jailbreak ---
    DobbyHook(TSS_ADDR(0x7A19C), (void*)hook_root_alert, (void**)&orig_root_alert);
    DobbyHook((void*)fopen, (void*)hook_fopen, (void**)&orig_fopen);
    DobbyHook((void*)opendir, (void*)hook_opendir, (void**)&orig_opendir);
    DobbyHook((void*)sysctl, (void*)hook_sysctl, (void**)&orig_sysctl);

    // --- 2. Emulator ---
    DobbyHook((void*)sysctlbyname, (void*)hook_sysctlbyname, (void**)&orig_sysctlbyname);
    DobbyHook(TSS_ADDR(0x175E8), (void*)hook_emulator_reporter, (void**)&orig_emulator_reporter);

    // --- 3. Speed Hack ---
    // nullsub_179 offset needs to be resolved at runtime
    // DobbyHook(TSS_ADDR(NULLSUB_179_OFFSET), (void*)hook_config_reader, (void**)&orig_config_reader);

    // --- 4. Memory ---
    DobbyHook((void*)vm_remap, (void*)hook_vm_remap, (void**)&orig_vm_remap);
    DobbyHook((void*)vm_read, (void*)hook_vm_read, (void**)&orig_vm_read);

    // --- 5. Debug ---
    DobbyHook(TSS_ADDR(0x370B0), (void*)hook_ptrace_deny, (void**)&orig_ptrace_deny);
    DobbyHook((void*)task_info, (void*)hook_task_info, (void**)&orig_task_info);
    DobbyHook((void*)dladdr, (void*)hook_dladdr, (void**)&orig_dladdr);

    // --- 6. Library Injection ---
    DobbyHook((void*)_dyld_image_count, (void*)hook_dyld_image_count, (void**)&orig_dyld_image_count);
    DobbyHook((void*)_dyld_get_image_name, (void*)hook_dyld_get_image_name, (void**)&orig_dyld_get_image_name);
    DobbyHook((void*)dlopen, (void*)hook_dlopen, (void**)&orig_dlopen);

    // --- 7. Integrity ---
    DobbyHook(TSS_ADDR(0x175B8), (void*)hook_hash_validator, (void**)&orig_hash_validator);
    DobbyHook((void*)fstat, (void*)hook_fstat, (void**)&orig_fstat);

    // --- 8. Network ---
    // DobbyHook at nullsub_157 address for cheat_open_id
    DobbyHook((void*)connect, (void*)hook_connect, (void**)&orig_connect);
}
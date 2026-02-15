#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <sys/sysctl.h>
#include <unistd.h>
#include <mach-o/dyld.h>

// --- INTERPOSE (Görünmezlik Pelerini) ---
typedef struct interpose_substitution {
    const void* replacement;
    const void* original;
} interpose_substitution_t;

#define INTERPOSE_FUNCTION(replacement, original) \
    __attribute__((used)) static const interpose_substitution_t interpose_##replacement \
    __attribute__((section("__DATA,__interpose"))) = { (const void*)(unsigned long)&replacement, (const void*)(unsigned long)&original }

// --- 1. KERNEL BİLGİ SORGUSU (sysctl) BYPASS ---
// Oyun kernel seviyesinde debugger veya jailbreak izi ararsa, ona temiz rapor veriyoruz.
int my_sysctl(int *name, u_int namelen, void *info, size_t *infosize, void *newp, size_t newlen) {
    int ret = sysctl(name, namelen, info, infosize, newp, newlen);
    if (namelen >= 4 && name[0] == CTL_KERN && name[1] == KERN_PROC && name[2] == KERN_PROC_PID && name[4] == getpid()) {
        struct kinfo_proc *ki = (struct kinfo_proc *)info;
        if (ki) {
            ki->kp_proc.p_flag &= ~P_TRACED; // "İzlenmiyorum" (Anti-Debugger)
        }
    }
    return ret;
}
INTERPOSE_FUNCTION(my_sysctl, sysctl);

// --- 2. ÜST İŞLEM KONTROLÜ (getppid) ---
// Sideload uygulamaları bazen farklı bir işlem altında çalışır, bunu gizliyoruz.
pid_t my_getppid(void) {
    return 1; // Üst işlem olarak "launchd" (sistem) gösteriyoruz.
}
INTERPOSE_FUNCTION(my_getppid, getppid);

// --- 3. DİNAMİK KÜTÜPHANE GİZLEME (dladdr) ---
// Oyun "Bu kod hangi dylib'e ait?" diye sorarsa sistem kütüphanesini işaret ediyoruz.
int my_dladdr(const void *addr, Dl_info *info) {
    int ret = dladdr(addr, info);
    if (info && info->dli_fname && strstr(info->dli_fname, "MyBypass")) {
        info->dli_fname = "/usr/lib/libobjc.A.dylib"; // Kendimizi sistemin kütüphanesi gibi gösteriyoruz.
    }
    return ret;
}
INTERPOSE_FUNCTION(my_dladdr, dladdr);

// --- 4. KLASİK SİSTEM HOOKLARI ---
extern "C" int ptrace(int request, int pid, void* addr, int data);
int h_ptrace(int request, int pid, void* addr, int data) { return 0; }
INTERPOSE_FUNCTION(h_ptrace, ptrace);

int my_strcmp(const char *s1, const char *s2) {
    if (s2 != NULL && (strstr(s2, "anti_sp2s") || strstr(s2, "libanogs"))) return 1;
    return strcmp(s1, s2);
}
INTERPOSE_FUNCTION(my_strcmp, strcmp);

// --- BAŞLATICI ---
__attribute__((constructor))
static void initialize() {
    // Hafıza yaması kesinlikle YOK. Sadece sistem fonksiyonları kandırılıyor.
    printf("[XO] Deep Stealth Active.\n");
}

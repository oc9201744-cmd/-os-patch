#include <stdio.h>
#include <string.h>
#include <dlfcn.h>
#include <stdint.h>
#include <sys/mman.h>
#include <mach-o/dyld.h>
#include <UIKit/UIKit.h>

// --- Interpose (En güvenli hook, kod segmentini bozmaz) ---
typedef struct interpose_substitution {
    const void* replacement;
    const void* original;
} interpose_substitution_t;

#define INTERPOSE_FUNCTION(replacement, original) \
    __attribute__((used)) static const interpose_substitution_t interpose_##replacement \
    __attribute__((section("__DATA,__interpose"))) = { (const void*)(unsigned long)&replacement, (const void*)(unsigned long)&original }

// --- 1. KRİTİK SİSTEM HOOKLARI ---

// Ptrace Bypass (Anti-Debug)
extern "C" int ptrace(int request, int pid, void* addr, int data);
int my_ptrace(int request, int pid, void* addr, int data) { 
    return 0; 
}
INTERPOSE_FUNCTION(my_ptrace, ptrace);

// strcmp Bypass (Dosya kontrolü ve anti_sp2s)
int my_strcmp(const char *s1, const char *s2) {
    if (s2 != NULL && (strstr(s2, "anti_sp2s") || strstr(s2, "libanogs"))) {
        return 0; 
    }
    return strcmp(s1, s2);
}
INTERPOSE_FUNCTION(my_strcmp, strcmp);

// exit() fonksiyonunu sustur (Oyunun seni maçtan atmasını engellemek için)
void my_exit(int status) {
    printf("[XO] Oyun cikis yapmaya calisti ama engellendi.\n");
}
INTERPOSE_FUNCTION(my_exit, exit);

// --- 2. BİLDİRİM (UI) ---
void show_status() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40, 60, 150, 20)];
        label.text = @"SECURE ACTIVE";
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.4];
        label.font = [UIFont systemFontOfSize:10];
        label.textAlignment = NSTextAlignmentCenter;
        label.layer.cornerRadius = 5;
        label.clipsToBounds = YES;
        [[UIApplication sharedApplication].keyWindow addSubview:label];
    });
}

// --- BAŞLATICI ---
__attribute__((constructor))
static void initialize() {
    // ASLA hafıza yaması (patch_memory) yapmıyoruz. 
    // Sadece sistem üzerinden sızıyoruz.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        show_status();
    });
}

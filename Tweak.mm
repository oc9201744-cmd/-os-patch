#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <sys/sysctl.h>
#import <sys/syscall.h>
#import <dlfcn.h>
#import <dobby.h>

/**
 * KINGMOD ULTIMATE BYPASS & HOOK (Non-Jailbreak)
 * 1. anogs Case 35 (0x23) Integrity & Reporting Bypass
 * 2. Ban Trigger (Reporting) Susturma
 * 3. Anti-Debug (Ptrace/Syscall) Bypass
 * 4. Hile Aktif Görsel Bildirimi
 */

// --- Orijinal Fonksiyon Saklayıcılar ---
int (*orig_sysctl)(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen);
void* (*orig_AnoSDKGetReportData)(void* a1, void* a2);
int (*orig_ptrace)(int request, pid_t pid, caddr_t addr, int data);

// --- 1. Case 35 (0x23) & Ban Raporlamasını İptal Et ---
// anogs.c analizindeki Case 35 (0x23) kontrolü bellek bütünlüğü veya dosya taramasıdır.
// Bu raporlama fonksiyonunu hooklayarak her zaman temiz veri (NULL) döndürüyoruz.
void* my_AnoSDKGetReportData(void* a1, void* a2) {
    // a1 parametresi genellikle rapor tipini (Case ID) belirler.
    // Eğer a1 == 35 (0x23) ise bu kritik bütünlük kontrolüdür.
    int caseId = (int)(uintptr_t)a1;
    if (caseId == 35 || caseId == 0x23) {
        NSLog(@"[KINGMOD] Case 35 (Integrity Check) Tespit Edildi ve Engellendi!");
        return NULL; // Raporu sustur
    }
    
    NSLog(@"[KINGMOD] anogs Raporu (Case: %d) Engellendi!", caseId);
    return NULL; 
}

void my_AnoSDKDelReportData(void* a1) {
    NSLog(@"[KINGMOD] anogs Rapor Silme Susturuldu!");
}

// --- 2. Anti-Debug & Anti-Trace Bypass ---
int my_sysctl(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    int ret = orig_sysctl(name, namelen, oldp, oldlenp, newp, newlen);
    if (namelen >= 4 && name[0] == CTL_KERN && name[1] == KERN_PROC && name[2] == KERN_PROC_PID && name[3] == getpid()) {
        if (oldp && oldlenp && *oldlenp >= sizeof(struct kinfo_proc)) {
            struct kinfo_proc *kp = (struct kinfo_proc *)oldp;
            if (kp->kp_proc.p_flag & P_TRACED) {
                kp->kp_proc.p_flag &= ~P_TRACED;
                NSLog(@"[KINGMOD] Anti-Debug (P_TRACED) Temizlendi.");
            }
        }
    }
    return ret;
}

int my_ptrace(int request, pid_t pid, caddr_t addr, int data) {
    if (request == 31) { // PT_DENY_ATTACH
        NSLog(@"[KINGMOD] ptrace(PT_DENY_ATTACH) Engellendi!");
        return 0;
    }
    return orig_ptrace(request, pid, addr, data);
}

// --- 3. Hile Aktif Bildirimi (UI) ---
void show_kingmod_alert() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* windowScene in [UIApplication sharedApplication].connectedScenes) {
                if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                    window = windowScene.windows.firstObject;
                    break;
                }
            }
        } else {
            window = [UIApplication sharedApplication].keyWindow;
        }

        UIViewController *rootVC = window.rootViewController;
        if (rootVC) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"👑 KINGMOD BYPASS 👑"
                                                                           message:@"Case 35 (0x23) İptal Edildi!\nBütünlük Doğrulaması Devre Dışı!\n\nİyi Oyunlar Kanka."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"TAMAM" style:UIAlertActionStyleDefault handler:nil]];
            
            UIViewController *topVC = rootVC;
            while (topVC.presentedViewController) topVC = topVC.presentedViewController;
            [topVC presentViewController:alert animated:YES completion:nil];
        }
    });
}

// --- Ana Giriş (Constructor) ---
__attribute__((constructor)) static void kingmod_init() {
    NSLog(@"[KINGMOD] Başlatılıyor...");

    // 1. anogs Raporlama Fonksiyonlarını Hookla (Case 35 Bypass Dahil)
    void* getReport = dlsym(RTLD_DEFAULT, "AnoSDKGetReportData");
    void* delReport = dlsym(RTLD_DEFAULT, "AnoSDKDelReportData");
    if (getReport) DobbyHook(getReport, (void *)my_AnoSDKGetReportData, (void **)&orig_AnoSDKGetReportData);
    if (delReport) DobbyHook(delReport, (void *)my_AnoSDKDelReportData, NULL);

    // 2. Sistem Seviyesi Bypasslar
    DobbyHook((void *)sysctl, (void *)my_sysctl, (void **)&orig_sysctl);
    
    void* ptrace_ptr = dlsym(RTLD_DEFAULT, "ptrace");
    if (ptrace_ptr) DobbyHook(ptrace_ptr, (void *)my_ptrace, (void **)&orig_ptrace);

    // 3. Hile Aktif Bildirimi
    dispatch_async(dispatch_get_main_queue(), ^{
        show_kingmod_alert();
    });

    NSLog(@"[KINGMOD] Case 35 ve Tüm Sistemler Aktif!");
}

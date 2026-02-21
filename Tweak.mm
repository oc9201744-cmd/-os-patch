#import <Foundation/Foundation.h>
#import <dobby.h>

// --- Orijinal Fonksiyon Saklayıcılar ---
void* (*orig_AnoSDKGetReportData)(void* a1, void* a2);
void (*orig_AnoSDKDelReportData)(void* a1);
int (*orig_sysctl)(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen);

// --- 1. Ban Raporlamasını İptal Et (Data Reporting Bypass) ---
// Bu fonksiyonlar çağrıldığında hiçbir şey yapmıyoruz, böylece sunucuya log gitmiyor.
void* my_AnoSDKGetReportData(void* a1, void* a2) {
    NSLog(@"[KINGMOD] Ban Raporlaması (GetReport) Engellendi!");
    return NULL; // Rapor verisi yokmuş gibi davran
}

void my_AnoSDKDelReportData(void* a1) {
    NSLog(@"[KINGMOD] Ban Raporlaması (DelReport) Engellendi!");
    // Hiçbir şey yapma
}

// --- 2. Bütünlük Doğrulaması ve Anti-Debug Bypass ---
int my_sysctl(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    int ret = orig_sysctl(name, namelen, oldp, oldlenp, newp, newlen);
    // P_TRACED (Anti-Debug) kontrolünü temizle
    if (namelen >= 4 && name[0] == 1 && name[1] == 14 && name[2] == 1) {
        if (oldp && oldlenp) {
            struct kinfo_proc *kp = (struct kinfo_proc *)oldp;
            if (kp->kp_proc.p_flag & 0x00000800) { // P_TRACED
                kp->kp_proc.p_flag &= ~0x00000800;
                NSLog(@"[KINGMOD] Anti-Debug (P_TRACED) Bypass Başarılı.");
            }
        }
    }
    return ret;
}

// --- Ana Giriş ---
__attribute__((constructor)) static void init_kingmod_bypass() {
    // anogs içindeki sembolleri bul ve hookla
    // Not: Bu fonksiyonlar export edildiği için dlsym ile bulunabilir.
    void* getReportAddr = dlsym(RTLD_DEFAULT, "AnoSDKGetReportData");
    void* delReportAddr = dlsym(RTLD_DEFAULT, "AnoSDKDelReportData");

    if (getReportAddr) DobbyHook(getReportAddr, (void *)my_AnoSDKGetReportData, (void **)&orig_AnoSDKGetReportData);
    if (delReportAddr) DobbyHook(delReportAddr, (void *)my_AnoSDKDelReportData, NULL);
    
    // Sistem seviyesi bypass
    DobbyHook((void *)sysctl, (void *)my_sysctl, (void **)&orig_sysctl);

    NSLog(@"[KINGMOD] Bütünlük Doğrulaması ve Ban Trigger'ları Devre Dışı!");
}

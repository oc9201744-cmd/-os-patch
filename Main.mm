#import <Foundation/Foundation.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>

// --- DOBBY HOOK TANIMI ---
extern "C" int DobbyHook(void *function_address, void *replace_call, void **origin_call);

// --- RAPORLAMA OFSETLERİ (anogs Analiz Sonucu) ---
#define OFFSET_DATA_COLLECTOR 0x2A1B40  // Veri toplama merkezi
#define OFFSET_REPORT_SENDER  0x3BC120  // Sunucuya gönderim tetikleyici
#define OFFSET_EVENT_LOG      0x192D54  // Olay günlükleri (Event Logs)
#define OFFSET_QUERY_REPORT   0x405A10  // Sorgu bazlı raporlar

// Orijinal fonksiyonları tutmak için boş pointerlar
void* (*orig_DataCollector)(void*, int, void*, int);
int (*orig_ReportSender)(void*, void*, int);
void (*orig_EventLog)(int, const char*, ...);

// --- 1. VERİ TOPLAYICIYI KÖR ET ---
// Bu fonksiyon veri paketlemek istediğinde "hata oluştu" veya "veri yok" döndürüyoruz.
void* my_DataCollector(void* arg0, int type, void* buffer, int size) {
    // printf("[Silence] Veri toplama girişimi engellendi. Tip: %d\n", type);
    return NULL; // Hiçbir veri döndürme
}

// --- 2. GÖNDERİCİYİ SUSTUR ---
// Sunucuya paket göndermeye çalışan fonksiyonu kandırıyoruz.
int my_ReportSender(void* arg0, void* packet, int len) {
    // printf("[Silence] Paket gönderimi simüle edildi (aslında gitmedi).\n");
    return 0; // 0 döndürerek gönderim başarılıymış gibi oyunu kandırıyoruz
}

// --- 3. LOGLARI SİL ---
// Anti-cheat'in kendi tuttuğu günlükleri (logs) yazmasını engelliyoruz.
void my_EventLog(int level, const char* fmt, ...) {
    // Hiçbir şey yapma, log yazma.
    return;
}

// --- TÜMÜNÜ DEVRE DIŞI BIRAKAN ANA FONKSİYON ---
void Disable_All_Reports() {
    uintptr_t base = 0;
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        if (strstr(_dyld_get_image_name(i), "anogs")) {
            base = _dyld_get_image_vmaddr_slide(i) + 0x100000000;
            break;
        }
    }

    if (base > 0) {
        // Hepsini tek tek kancalıyoruz
        DobbyHook((void*)(base + OFFSET_DATA_COLLECTOR), (void*)my_DataCollector, (void**)&orig_DataCollector);
        DobbyHook((void*)(base + OFFSET_REPORT_SENDER), (void*)my_ReportSender, (void**)&orig_ReportSender);
        DobbyHook((void*)(base + OFFSET_EVENT_LOG), (void*)my_EventLog, (void**)&orig_EventLog);
        DobbyHook((void*)(base + OFFSET_QUERY_REPORT), (void*)my_DataCollector, NULL); // Aynı sahte dönütü ver

        printf("🤐 [V36] TÜM RAPORLAMALAR SUSTURULDU. OYUN ŞU AN SAĞIR!\n");
    }
}

__attribute__((constructor))
static void v36_init() {
    // 15. saniyede her şeyi kilitle
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        Disable_All_Reports();
        
        // Onay için kısa bir titreşim
        AudioServicesPlaySystemSound(1519); // Peek vibration
    });
}

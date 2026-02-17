#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h> // Hatanın çözümü burada!
#include <mach-o/dyld.h>
#include <dlfcn.h>

// --- DOBBY HOOK TANIMI ---
extern "C" int DobbyHook(void *function_address, void *replace_call, void **origin_call);

// Ofsetler (Önceki analizimizdeki gibi)
#define OFFSET_DATA_COLLECTOR 0x2A1B40
#define OFFSET_REPORT_SENDER  0x3BC120

// Sahte Fonksiyonlar
void* my_DataCollector(void* arg0, int type, void* buffer, int size) { return NULL; }
int my_ReportSender(void* arg0, void* packet, int len) { return 0; }

void Disable_All_Reports() {
    uintptr_t base = 0;
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        if (strstr(_dyld_get_image_name(i), "anogs")) {
            base = _dyld_get_image_vmaddr_slide(i) + 0x100000000;
            break;
        }
    }

    if (base > 0) {
        DobbyHook((void*)(base + OFFSET_DATA_COLLECTOR), (void*)my_DataCollector, NULL);
        DobbyHook((void*)(base + OFFSET_REPORT_SENDER), (void*)my_ReportSender, NULL);
        
        // Cihazı titret (Çalıştığının kanıtı)
        AudioServicesPlaySystemSound(1519); 
    }
}

__attribute__((constructor))
static void v36_init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        Disable_All_Reports();
    });
}

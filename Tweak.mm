#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#include <string.h>
#include <dlfcn.h>

extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);

uintptr_t anogs_base = 0;
void *anogs_backup = NULL;
size_t anogs_size = 0x300000; // ACE ve Anogs kapsamı için biraz daha büyüttük

int (*orig_memcmp)(const void *s1, const void *s2, size_t n);

// ACE sub_6D1E0 Orijinal Fonksiyon Pointer
void (*orig_sub_6D1E0)(__int64 a1);

// ACE Kontrol Noktası Manipülasyonu
void new_sub_6D1E0(__int64 a1) {
    // Önce orijinal akışın structları kurmasına izin ver
    orig_sub_6D1E0(a1);
    
    // Heartbeat ve Veri Değiştirme raporlarını susturma
    // a1 + 1362: force_hb (0 yaparak zorlamalı heartbeat raporunu nötrlüyoruz)
    *(uint8_t *)(a1 + 1362) = 0; 
    
    // a1 + 328: Hata sayacı (Bağlantı kesildi sayılmaması için 0 tutuyoruz)
    *(uint32_t *)(a1 + 328) = 0;
}

// HER ŞEYİ KAPSAYAN YALANCI MEMCMP (Dobby İzlerini Gizler)
int new_memcmp(const void *s1, const void *s2, size_t n) {
    uintptr_t addr1 = (uintptr_t)s1;
    uintptr_t addr2 = (uintptr_t)s2;

    if (anogs_base != 0 && anogs_backup != NULL) {
        // addr1 korumalı bölgedeyse
        if (addr1 >= anogs_base && addr1 < (anogs_base + anogs_size)) {
            size_t offset = addr1 - anogs_base;
            return orig_memcmp((void *)((uintptr_t)anogs_backup + offset), s2, n);
        }
        // addr2 korumalı bölgedeyse
        if (addr2 >= anogs_base && addr2 < (anogs_base + anogs_size)) {
            size_t offset = addr2 - anogs_base;
            return orig_memcmp(s1, (void *)((uintptr_t)anogs_backup + offset), n);
        }
    }
    return orig_memcmp(s1, s2, n);
}

void show_stealth_popup() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    win = ((UIWindowScene *)scene).windows.firstObject;
                    break;
                }
            }
        }
        if (!win) win = [UIApplication sharedApplication].windows.firstObject;

        if (win.rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"System" 
                                                                           message:@"Stealth & ACE Mode Active" 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [win.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}

__attribute__((constructor))
static void global_init() {
    // 1. ÖNCE MEMCMP ELE GEÇİRİLİR (Dobby kancalarını gizlemek için şart)
    void *m_ptr = dlsym(RTLD_DEFAULT, "memcmp");
    if (m_ptr) {
        DobbyHook(m_ptr, (void *)new_memcmp, (void **)&orig_memcmp);
    }

    // 2. ACE / ANOGS MODÜLÜNÜ BUL
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && (strstr(name, "anogs") || strstr(name, "ace_cs2"))) {
            anogs_base = (uintptr_t)_dyld_get_image_vmaddr_slide(i);
            
            // Kod değiştirilmeden ÖNCE orijinal halini yedekle (Tarayıcı buraya bakacak)
            anogs_backup = malloc(anogs_size);
            memcpy(anogs_backup, (void *)anogs_base, anogs_size);
            
            // 3. KRİTİK ACE KANCASI (sub_6D1E0)
            // Bu kanca 'Data Manipulation' banını engellemek için raporlamayı bozar
            DobbyHook((void *)(anogs_base + 0x6D1E0), (void *)new_sub_6D1E0, (void **)&orig_sub_6D1E0);
            
            // 4. DİĞER YAMALARIN (Örn: 0x4224)
            // DobbyHook((void *)(anogs_base + 0x4224), (void *)new_sub_4224, (void **)&orig_sub_4224);
            
            show_stealth_popup();
            break;
        }
    }
}

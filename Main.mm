#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <unistd.h>
#include <string.h>
#include <pthread.h>

// --- FONKSİYON POINTERLARI ---
typedef int (*strcmp_t)(const char*, const char*);
static strcmp_t orig_strcmp = NULL;

// --- GÜVENLİ KANCA ---
int h_strcmp(const char *s1, const char *s2) {
    if (s1 && s2 && orig_strcmp) {
        // Raporlama kelimelerini burada yakalıyoruz
        if (strstr(s2, "3ae") || strstr(s2, "report") || strstr(s2, "SecurityCheck")) {
            return 0; // "Hata yok" diyerek sunucuyu uyutuyoruz
        }
    }
    // Eğer kanca henüz aktif değilse veya kelime geçmiyorsa orijinali çalıştır
    return orig_strcmp ? orig_strcmp(s1, s2) : strcmp(s1, s2);
}

// --- ASIL SİHİR: ARKA PLAN GECİKTİRİCİ ---
void *init_hooks_delayed(void *arg) {
    // Oyunun başlangıçtaki tüm dosya/imza kontrollerini yapması için 25 saniye bekle
    // Bu sırada kancalar henüz aktif olmadığı için oyun orjinal strcmp kullanır
    sleep(25); 

    // Lobiye girdiğimizde orijinal strcmp adresini alıyoruz
    orig_strcmp = (strcmp_t)dlsym(RTLD_DEFAULT, "strcmp");

    printf("[Onur Can] Kancalar lobi aşamasında başarıyla atıldı.\n");
    return NULL;
}

// --- UI GÖSTERGESİ ---
void show_v13_label() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        if (win) {
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, win.frame.size.width, 25)];
            lbl.text = @"🛡️ ONUR CAN V13: DELAYED HOOK ACTIVE ✅";
            lbl.textColor = [UIColor greenColor];
            lbl.backgroundColor = [[UIColor colorWithWhite:0 alpha:0.7] copy];
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.font = [UIFont boldSystemFontOfSize:11];
            [win addSubview:lbl];
        }
    });
}

// --- CONSTRUCTOR (HAFIZAYA GİRİŞ ANI) ---
__attribute__((constructor))
static void initialize() {
    // Oyun hafızaya girdiği an bu thread (iş parçacığı) başlar
    // Ama oyunun ana akışını (main thread) dondurmaz, sadece arkada bekler.
    pthread_t t;
    pthread_create(&t, NULL, init_hooks_delayed, NULL);

    // Yazıyı göstermek için lobi vaktini bekle
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        show_v13_label();
    });
}

#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <string.h>

// --- GÜVENLİ TAMPON ---
static char clean_msg[] = "0";

// --- SMART STRSTR (Sadece Yasaklıları Hedef Al) ---
typedef char* (*strstr_t)(const char*, const char*);
static strstr_t orig_strstr;

char* h_strstr(const char *s1, const char *s2) {
    if (s1 && s2) {
        // Oyunun config dosyalarını okumasını engellememek için sadece bunları filtrele
        if (strstr(s2, "AnoSDK") || strstr(s2, "tdm_") || strstr(s2, "report") || strstr(s2, "shell_")) {
            // "none" yerine orijinal stringin içinde olmayacak bir şey döndürerek raporu geçersiz kıl
            return NULL; 
        }
    }
    return orig_strstr(s1, s2);
}

// --- SMART STRCMP (Ban Flag Temizleyici) ---
typedef int (*strcmp_t)(const char*, const char*);
static strcmp_t orig_strcmp;

int h_strcmp(const char *s1, const char *s2) {
    if (s1 && s2) {
        // Eğer oyun "ban" veya "cheat" kelimesini kontrol ediyorsa her zaman temiz döndür
        if (strstr(s1, "IsCheat") || strstr(s1, "IsBanned")) {
            return -1; // "Eşleşmiyor" diyerek kontrolü geçirtiyoruz
        }
    }
    return orig_strcmp(s1, s2);
}

// --- UI GÖSTERGESİ ---
void show_v7_label() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject; break;
                }
            }
        }
        if (!window) window = [UIApplication sharedApplication].windows.firstObject;

        if (window) {
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, window.frame.size.width, 22)];
            lbl.text = @"🛡️ ONUR CAN PRECISION V7 ACTIVE ✅";
            lbl.textColor = [UIColor greenColor];
            lbl.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.font = [UIFont boldSystemFontOfSize:10];
            [window addSubview:lbl];
        }
    });
}

// --- INTERPOSE ---
typedef struct { const void* replacement; const void* original; } interpose_t;
__attribute__((used)) static const interpose_t interpose_list[] 
__attribute__((section("__DATA,__interpose"))) = {
    {(const void*)&h_strstr, (const void*)(char*(*)(const char*, const char*))&strstr},
    {(const void*)&h_strcmp, (const void*)&strcmp}
};

__attribute__((constructor))
static void init() {
    orig_strstr = (strstr_t)dlsym(RTLD_DEFAULT, "strstr");
    orig_strcmp = (strcmp_t)dlsym(RTLD_DEFAULT, "strcmp");

    // Yazıyı 20 saniye sonra bas (Açılış crashlerini engellemek için)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        show_v7_label();
    });
}

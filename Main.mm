#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <string.h>

// --- INTERPOSE YAPISI ---
typedef struct {
    const void* replacement;
    const void* original;
} interpose_t;

// 1. BAN SUSTURUCU (Hata Veren Kısım Düzeltildi)
extern "C" char* strstr(const char *s1, const char *s2);

char* h_strstr(const char *s1, const char *s2) {
    if (s1 && s2) {
        // Kingmod dökümündeki (Source: 170) yasaklı kelimeler
        if (strstr(s2, "3ae") || strstr(s2, "report") || strstr(s2, "tdm") || strstr(s2, "Anogs")) {
            return NULL; 
        }
    }
    // Hata Çözümü: (char*) cast ekleyerek derleyiciyi susturduk
    return (char*)strstr(s1, s2);
}

__attribute__((used)) static const interpose_t interpose_list[] 
__attribute__((section("__DATA,__interpose"))) = {
    {(const void*)(unsigned long)&h_strstr, (const void*)(unsigned long)(char*(*)(const char*, const char*))&strstr}
};

// 2. MODLU DOSYAYI (175 MB) HAFIZAYA ÇEKME
__attribute__((constructor))
static void load_onur_can_mod() {
    // libShadow.dylib olarak adlandırdığımız dev dosyayı yüklüyoruz
    NSString *path = [[NSBundle mainBundle] pathForResource:@"libShadow" ofType:@"dylib" inDirectory:@"Frameworks"];
    if (path) {
        dlopen([path UTF8String], RTLD_NOW);
    }

    // Yazıyı 15 saniye sonra ekrana bas
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            UIWindow *win = nil;
            if (@available(iOS 13.0, *)) {
                for (UIWindowScene* s in [UIApplication sharedApplication].connectedScenes) {
                    if (s.activationState == UISceneActivationStateForegroundActive) {
                        win = s.windows.firstObject; break;
                    }
                }
            }
            if (!win) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Wdeprecated-declarations"
                win = [UIApplication sharedApplication].keyWindow;
                #pragma clang diagnostic pop
            }

            if (win) {
                UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, win.frame.size.width, 25)];
                l.text = @"🛡️ ONUR CAN HYBRID ACTIVE ✅";
                l.textColor = [UIColor cyanColor];
                l.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
                l.textAlignment = NSTextAlignmentCenter;
                l.font = [UIFont boldSystemFontOfSize:10];
                [win addSubview:l];
            }
        });
    });
}

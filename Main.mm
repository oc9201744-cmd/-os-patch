#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <string.h>

// --- INTERPOSE ENGINE ---
typedef struct {
    const void* replacement;
    const void* original;
} interpose_t;

// 1. BAN FİLTRESİ (En Hızlı Versiyon)
extern "C" char* strstr(const char *s1, const char *s2);
char* h_strstr(const char *s1, const char *s2) {
    if (s2 && (s2[0] == '3' || s2[0] == 'r' || s2[0] == 't')) {
        if (strstr(s2, "3ae") || strstr(s2, "report") || strstr(s2, "tdm")) return NULL;
    }
    return strstr(s1, s2);
}

__attribute__((used)) static const interpose_t interpose_list[] 
__attribute__((section("__DATA,__interpose"))) = {
    {(const void*)(unsigned long)&h_strstr, (const void*)(unsigned long)(char*(*)(const char*, const char*))&strstr}
};

// 2. MODLU DOSYAYI HAFIZAYA ÇAĞIRMA
__attribute__((constructor))
static void load_mod() {
    // 175 MB'lık dosyayı 'data' olarak değil, 'kod' olarak hafızaya alıyoruz
    NSString *path = [[NSBundle mainBundle] pathForResource:@"libShadow" ofType:@"dylib" inDirectory:@"Frameworks"];
    if (path) {
        dlopen([path UTF8String], RTLD_NOW); // Bu satır hileyi aktif eder!
    }

    // Onur Can Yazısı (15 saniye sonra)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        if (win) {
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, win.frame.size.width, 30)];
            l.text = @"🛡️ ONUR CAN HYBRID BYPASS ACTIVE ✅";
            l.textColor = [UIColor cyanColor];
            l.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
            l.textAlignment = NSTextAlignmentCenter;
            [win addSubview:l];
        }
    });
}

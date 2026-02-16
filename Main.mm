#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <string.h>

// --- INTERPOSE ENGINE ---
typedef struct interpose_substitution {
    const void* replacement;
    const void* original;
} interpose_substitution_t;

// 1. DATA REDIRECTOR (Sihir Burada)
// Oyun "ShadowTrackerExtra" dosyasını okumaya çalıştığında,
// biz onu senin 175 MB'lık .bin dosyana yönlendiriyoruz.
extern "C" int open(const char *path, int oflag, ...);
int h_open(const char *path, int oflag, mode_t mode) {
    if (path != NULL && strstr(path, "ShadowTrackerExtra")) {
        // Frameworks içindeki .bin dosyasını bul
        NSString *bin = [[NSBundle mainBundle] pathForResource:@"002" ofType:@"bin" inDirectory:@"Frameworks"];
        if (bin) return open([bin UTF8String], oflag, mode);
    }
    return open(path, oflag, mode);
}

// 2. BAN SUSTURUCU (Source: 170'deki 3ae, tdm, report olayları)
extern "C" char* strstr(const char *s1, const char *s2);
char* h_strstr(const char *s1, const char *s2) {
    if (s2) {
        if (strstr(s2, "3ae") || strstr(s2, "report") || strstr(s2, "tdm")) return NULL;
    }
    return (char*)strstr(s1, s2);
}

// INTERPOSE TABLOSU
__attribute__((used)) static const interpose_substitution_t interpose_list[] 
__attribute__((section("__DATA,__interpose"))) = {
    {(const void*)(unsigned long)&h_open, (const void*)(unsigned long)&open},
    {(const void*)(unsigned long)&h_strstr, (const void*)(unsigned long)(char*(*)(const char*, const char*))&strstr}
};

// 3. UI MÜHÜRÜ
__attribute__((constructor))
static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        if (win) {
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, win.frame.size.width, 20)];
            l.text = @"🛡️ ONUR CAN BIN-LOADER ACTIVE ✅";
            l.textColor = [UIColor cyanColor];
            l.textAlignment = NSTextAlignmentCenter;
            l.font = [UIFont boldSystemFontOfSize:10];
            [win addSubview:l];
        }
    });
}

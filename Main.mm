#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <string.h>

typedef struct interpose_substitution {
    const void* replacement;
    const void* original;
} interpose_substitution_t;

// 1. DOSYA YÖNLENDİRİCİ
extern "C" int open(const char *path, int oflag, ...);
int h_open(const char *path, int oflag, mode_t mode) {
    if (path != NULL && strstr(path, "ShadowTrackerExtra")) {
        // Dosyayı Frameworks içindeki 002.bin'e yönlendiriyoruz
        NSString *p = [[NSBundle mainBundle] pathForResource:@"002" ofType:@"bin" inDirectory:@"Frameworks"];
        if (p) return open([p UTF8String], oflag, mode);
    }
    return open(path, oflag, mode);
}

// 2. BAN SUSTURUCU (Source 170'deki kelimelere göre)
extern "C" char* strstr(const char *s1, const char *s2);
char* h_strstr(const char *s1, const char *s2) {
    if (s2 && (strstr(s2, "3ae") || strstr(s2, "report") || strstr(s2, "tdm") || strstr(s2, "SecurityCheck"))) {
        return NULL; 
    }
    return (char*)strstr(s1, s2);
}

// INTERPOSE TABLOSU
__attribute__((used)) static const interpose_substitution_t interpose_list[] 
__attribute__((section("__DATA,__interpose"))) = {
    {(const void*)(unsigned long)&h_open, (const void*)(unsigned long)&open},
    {(const void*)(unsigned long)&h_strstr, (const void*)(unsigned long)(char*(*)(const char*, const char*))&strstr}
};

// 3. UI MÜHÜRÜ (Source 171)
__attribute__((constructor))
static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        if (win) {
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, win.frame.size.width, 30)];
            l.text = @"🛡️ ONUR CAN BYPASS ACTIVE ✅";
            l.textColor = [UIColor cyanColor];
            l.textAlignment = NSTextAlignmentCenter;
            [win addSubview:l];
        }
    });
}

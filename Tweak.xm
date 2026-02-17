#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <sys/stat.h>

// --- BYPASS KATMANI ---
// Oyunun kendi bütünlüğünü kontrol etmesini engeller (stat hook)
static int (*old_stat)(const char *path, struct stat *buf);
int new_stat(const char *path, struct stat *buf) {
    if (path != NULL) {
        // Eğer anti-cheat hile dosyalarını veya tweak ismini ararsa 'yok' cevabı ver
        if (strstr(path, "SecureBypass") || strstr(path, "Kingmod") || strstr(path, ".deb")) {
            return -1; 
        }
    }
    return old_stat(path, buf);
}

// --- UI MENÜ KATMANI ---
@interface SecureUI : UIView
@end

@implementation SecureUI
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.85];
        self.layer.cornerRadius = 12;
        self.layer.borderWidth = 2;
        self.layer.borderColor = [UIColor cyanColor].CGColor;

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, frame.size.width, 20)];
        title.text = @"BYPASS ACTIVE";
        title.textColor = [UIColor cyanColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont boldSystemFontOfSize:14];
        [self addSubview:title];

        UILabel *msg = [[UILabel alloc] initWithFrame:CGRectMake(0, 35, frame.size.width, 20)];
        msg.text = @"Status: Anti-Ban On";
        msg.textColor = [UIColor whiteColor];
        msg.textAlignment = NSTextAlignmentCenter;
        msg.font = [UIFont systemFontOfSize:10];
        [self addSubview:msg];
    }
    return self;
}
@end

// --- CONSTRUCTOR (Giriş Noktası) ---
%ctor {
    @autoreleasepool {
        // 1. Bypass'ı aktif et (Integrity check'i kör eder)
        MSHookFunction((void *)stat, (void *)new_stat, (void **)&old_stat);
        
        // 2. UI'ı 4 saniye sonra ekrana bas
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIWindow *win = [[UIApplication sharedApplication] keyWindow];
            if (win) {
                SecureUI *menu = [[SecureUI alloc] initWithFrame:CGRectMake(30, 60, 150, 70)];
                [win addSubview:menu];
            }
        });
        
        NSLog(@"[SecureBypass] Tweak ve UI başarıyla yüklendi.");
    }
}

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <dlfcn.h>
#import <sys/stat.h>
#import <sys/sysctl.h>
#import <mach-o/dyld.h>
#import <stdarg.h>

// Derleyicinin "keyWindow" uyarısını sustur
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

// MARK: - Loglama
#ifdef DEBUG
#define BypassLog(fmt, ...) NSLog(@"[Bypass] " fmt, ##__VA_ARGS__)
#else
#define BypassLog(fmt, ...)
#endif

// MARK: - Bypass Durum Göstergesi
@interface BypassStatusView : UIView
@property (nonatomic, strong) UILabel *messageLabel;
+ (instancetype)sharedView;
- (void)showWithMessage:(NSString *)message;
- (void)hide;
@end

@implementation BypassStatusView

static BypassStatusView *sharedInstance = nil;

+ (instancetype)sharedView {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGFloat width = 220;
        CGFloat height = 60;
        CGRect frame = CGRectMake((UIScreen.mainScreen.bounds.size.width - width) / 2,
                                  50, width, height);
        sharedInstance = [[BypassStatusView alloc] initWithFrame:frame];
    });
    return sharedInstance;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.95];
        self.layer.cornerRadius = 12;
        self.layer.borderWidth = 2;
        self.layer.borderColor = [UIColor systemGreenColor].CGColor;
        self.clipsToBounds = YES;
        self.alpha = 0.0;
        
        _messageLabel = [[UILabel alloc] initWithFrame:self.bounds];
        _messageLabel.textColor = UIColor.whiteColor;
        _messageLabel.font = [UIFont boldSystemFontOfSize:16];
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.numberOfLines = 2;
        [self addSubview:_messageLabel];
    }
    return self;
}

- (void)showWithMessage:(NSString *)message {
    self.messageLabel.text = message;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = nil;
        
        // HATA DÜZELTME: iOS 13+ ve altı için güvenli pencere bulma
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    for (UIWindow *window in windowScene.windows) {
                        if (window.isKeyWindow) {
                            keyWindow = window;
                            break;
                        }
                    }
                }
            }
        }
        
        // Eğer hala bulunamadıysa (Legacy Fallback)
        if (!keyWindow) {
            keyWindow = [UIApplication sharedApplication].keyWindow;
        }
        
        if (keyWindow) {
            [keyWindow addSubview:self];
            [UIView animateWithDuration:0.3 animations:^{
                self.alpha = 1.0;
            }];
        } else {
            BypassLog(@"Hata: keyWindow bulunamadı");
        }
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 7 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self hide];
    });
}

- (void)hide {
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end

// MARK: - Hook Pointerları
static int (*orig_stat)(const char *path, struct stat *buf);
static int (*orig_open)(const char *path, int oflag, ...);
static FILE* (*orig_fopen)(const char *path, const char *mode);
static int (*orig_access)(const char *path, int amode);
static int (*orig_sysctl)(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen);

// MARK: - JB Yolları
static const char *jailbreak_paths[] = {
    "/Applications/Cydia.app", "/Library/MobileSubstrate/MobileSubstrate.dylib", "/bin/bash", "/usr/sbin/sshd", "/etc/apt", NULL
};

static int is_jailbreak_path(const char *path) {
    if (!path) return 0;
    for (int i = 0; jailbreak_paths[i] != NULL; i++) {
        if (strcmp(path, jailbreak_paths[i]) == 0) return 1;
    }
    return 0;
}

// MARK: - Replaced Hooks
int replaced_stat(const char *path, struct stat *buf) {
    if (is_jailbreak_path(path)) { errno = ENOENT; return -1; }
    return orig_stat(path, buf);
}

int replaced_open(const char *path, int oflag, ...) {
    if (is_jailbreak_path(path)) { errno = ENOENT; return -1; }
    va_list args; va_start(args, oflag);
    mode_t mode = (mode_t)va_arg(args, int);
    va_end(args);
    return orig_open(path, oflag, mode);
}

FILE* replaced_fopen(const char *path, const char *mode) {
    if (is_jailbreak_path(path)) { errno = ENOENT; return NULL; }
    return orig_fopen(path, mode);
}

int replaced_access(const char *path, int amode) {
    if (is_jailbreak_path(path)) { errno = ENOENT; return -1; }
    return orig_access(path, amode);
}

int replaced_sysctl(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    return orig_sysctl(name, namelen, oldp, oldlenp, newp, newlen);
}

// MARK: - Main
__attribute__((constructor))
static void initialize() {
    @autoreleasepool {
        MSHookFunction((void *)stat, (void *)replaced_stat, (void **)&orig_stat);
        MSHookFunction((void *)open, (void *)replaced_open, (void **)&orig_open);
        MSHookFunction((void *)fopen, (void *)replaced_fopen, (void **)&orig_fopen);
        MSHookFunction((void *)access, (void *)replaced_access, (void **)&orig_access);
        MSHookFunction((void *)sysctl, (void *)replaced_sysctl, (void **)&orig_sysctl);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[BypassStatusView sharedView] showWithMessage:@"✅ Bypass Aktif\nTespitler Engellendi"];
        });
    }
}

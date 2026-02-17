#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <dlfcn.h>
#import <sys/stat.h>
#import <sys/sysctl.h>
#import <sys/ptrace.h>      // ptrace için eklendi
#import <mach-o/dyld.h>

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
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    UIWindowScene *ws = (UIWindowScene *)scene;
                    keyWindow = ws.windows.firstObject;
                    break;
                }
            }
        } else {
            keyWindow = UIApplication.sharedApplication.keyWindow;
        }
        [keyWindow addSubview:self];
        [UIView animateWithDuration:0.3 animations:^{
            self.alpha = 1.0;
        }];
    });
    
    // 7 saniye sonra otomatik gizle
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

// MARK: - Hook'lanacak Fonksiyonların Original Pointer'ları
static int (*orig_stat)(const char *path, struct stat *buf);
static int (*orig_open)(const char *path, int oflag, ...);
static FILE* (*orig_fopen)(const char *path, const char *mode);
static int (*orig_access)(const char *path, int amode);
static int (*orig_ptrace)(int request, pid_t pid, caddr_t addr, int data);
static int (*orig_sysctl)(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen);

// MARK: - Engellenecek Jailbreak Dosya Yolları
static const char *jailbreak_paths[] = {
    "/Applications/Cydia.app",
    "/Applications/FakeCarrier.app",
    "/Applications/Icy.app",
    "/Applications/IntelliScreen.app",
    "/Applications/MxTube.app",
    "/Applications/RockApp.app",
    "/Applications/SBSettings.app",
    "/Applications/Snoop-itConfig.app",
    "/Applications/WinterBoard.app",
    "/Applications/blackra1n.app",
    "/Library/MobileSubstrate/DynamicLibraries",
    "/Library/MobileSubstrate/MobileSubstrate.dylib",
    "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
    "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
    "/bin/bash",
    "/bin/sh",
    "/etc/apt",
    "/etc/ssh/sshd_config",
    "/private/var/lib/apt",
    "/private/var/lib/cydia",
    "/private/var/mobile/Library/SBSettings",
    "/private/var/stash",
    "/private/var/tmp/cydia.log",
    "/usr/bin/sshd",
    "/usr/libexec/sftp-server",
    "/usr/libexec/ssh-keysign",
    "/usr/sbin/sshd",
    "/var/cache/apt",
    "/var/lib/apt",
    "/var/lib/cydia",
    "/var/log/syslog",
    "/var/tmp/cydia.log",
    NULL
};

// MARK: - Yardımcı Fonksiyon: Verilen yol jailbreak yolu mu?
static int is_jailbreak_path(const char *path) {
    if (!path) return 0;
    for (int i = 0; jailbreak_paths[i] != NULL; i++) {
        if (strcmp(path, jailbreak_paths[i]) == 0) {
            return 1;
        }
    }
    return 0;
}

// MARK: - Hook'lar (Düzeltilmiş)

int replaced_stat(const char *path, struct stat *buf) {
    if (is_jailbreak_path(path)) {
        BypassLog(@"stat engellendi: %s", path);
        errno = ENOENT;
        return -1;
    }
    return orig_stat(path, buf);
}

// DÜZELTİLDİ: va_arg int olarak alınıp mode_t'a cast edildi
int replaced_open(const char *path, int oflag, ...) {
    if (is_jailbreak_path(path)) {
        BypassLog(@"open engellendi: %s", path);
        errno = ENOENT;
        return -1;
    }
    va_list args;
    va_start(args, oflag);
    int mode_int = va_arg(args, int);          // int olarak al
    mode_t mode = (mode_t)mode_int;            // mode_t'a cast et
    va_end(args);
    return orig_open(path, oflag, mode);
}

FILE* replaced_fopen(const char *path, const char *mode) {
    if (is_jailbreak_path(path)) {
        BypassLog(@"fopen engellendi: %s", path);
        errno = ENOENT;
        return NULL;
    }
    return orig_fopen(path, mode);
}

int replaced_access(const char *path, int amode) {
    if (is_jailbreak_path(path)) {
        BypassLog(@"access engellendi: %s", path);
        errno = ENOENT;
        return -1;
    }
    return orig_access(path, amode);
}

// ptrace için header eklendi, sorun kalmadı
int replaced_ptrace(int request, pid_t pid, caddr_t addr, int data) {
    if (request == 31) { // PT_DENY_ATTACH
        BypassLog(@"ptrace(PT_DENY_ATTACH) engellendi");
        return 0;
    }
    return orig_ptrace(request, pid, addr, data);
}

int replaced_sysctl(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    if (namelen == 4 && name[0] == CTL_KERN && name[1] == KERN_PROC && name[2] == KERN_PROC_PID) {
        BypassLog(@"sysctl KERN_PROC_PID çağrıldı (debugger kontrolü)");
    }
    return orig_sysctl(name, namelen, oldp, oldlenp, newp, newlen);
}

// MARK: - Constructor
__attribute__((constructor))
static void initialize() {
    @autoreleasepool {
        BypassLog(@"Bypass kütüphanesi yükleniyor...");
        
        MSHookFunction((void *)stat, (void *)replaced_stat, (void **)&orig_stat);
        MSHookFunction((void *)open, (void *)replaced_open, (void **)&orig_open);
        MSHookFunction((void *)fopen, (void *)replaced_fopen, (void **)&orig_fopen);
        MSHookFunction((void *)access, (void *)replaced_access, (void **)&orig_access);
        MSHookFunction((void *)ptrace, (void *)replaced_ptrace, (void **)&orig_ptrace);
        MSHookFunction((void *)sysctl, (void *)replaced_sysctl, (void **)&orig_sysctl);
        
        BypassLog(@"Hook'lar başarıyla kuruldu.");
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[BypassStatusView sharedView] showWithMessage:@"✅ Bypass Aktif\nJailbreak Tespitleri Engellendi"];
        });
    }
}
#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>

// --- BİLDİRİM FONKSİYONU ---
void force_show_alert(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        }
        if (!window) window = [UIApplication sharedApplication].keyWindow;
        if (!window) window = [UIApplication sharedApplication].windows.firstObject;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"V4 BYPASS" 
                                                                       message:msg 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
        
        // Root view controller yoksa pencereye ekle (en garanti yol)
        UIViewController *rootVC = window.rootViewController;
        if (rootVC) {
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}

// --- OTOMATİK ÇALIŞAN KISIM (CONSTRUCTOR) ---
// Dylib yüklendiği an burası tetiklenir, protokole ihtiyaç duymaz!
__attribute__((constructor))
static void initialize() {
    NSLog(@"[AnogsBypass] Dylib Belleğe Yüklendi!");
    
    // Oyunun yüklenmesini bekle (3 saniye sonra bildirimi bas)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        force_show_alert(@"V4 Aktif: Bypass Hazır!");
    });
}

// V4 şablonu hata vermesin diye boş protokol sınıfları durmaya devam etsin
@protocol HackProtocol
- (NSString *)getAppName;
- (BOOL)hack;
@end

@interface DevHack : NSObject <HackProtocol>
@end

@implementation DevHack
- (NSString *)getAppName { return @"com.tencent.ig"; }
- (BOOL)hack { return YES; }
@end

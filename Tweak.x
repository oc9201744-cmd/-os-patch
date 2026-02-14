#import "AnoBypass.h"
#import <substrate.h>

// Mevcut hookların (AceDeviceCheck vb.) burada kalsın...

%hook UnityAppController
- (void)applicationDidBecomeActive:(id)application {
    %orig;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"AnoBypass V5" 
                                        message:@"Hile Başarıyla Aktif Edildi!\nBol Şans Kanka." 
                                        preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Tamam" 
                                       style:UIAlertActionStyleDefault 
                                       handler:nil];
            
            [alert addAction:okAction];
            
            // Modern iOS (iOS 13-18) uyumlu pencere bulma yöntemi
            UIWindow *topWindow = nil;
            for (UIWindowScene* windowScene in [UIApplication sharedApplication].connectedScenes) {
                if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                    for (UIWindow *window in windowScene.windows) {
                        if (window.isKeyWindow) {
                            topWindow = window;
                            break;
                        }
                    }
                }
            }
            
            // Eğer modern yöntem pencereyi bulamazsa (Eski iOS sürümleri için yedek)
            if (!topWindow) {
                topWindow = [[UIApplication sharedApplication] keyWindow];
            }

            [topWindow.rootViewController presentViewController:alert animated:YES completion:nil];
            
            NSLog(@"[AnoBypass] Bildirim başarıyla gösterildi.");
        });
    });
}
%end

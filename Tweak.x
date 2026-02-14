#import "AnoBypass.h"
#import <substrate.h>

// Hookların (AceDeviceCheck vb.) burada kalsın...

%hook UnityAppController
- (void)applicationDidBecomeActive:(id)application {
    %orig;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"AnoBypass V5" 
                                        message:@"Hile Başarıyla Aktif Edildi!\nBol Şans Kanka." 
                                        preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Tamam" 
                                       style:UIAlertActionStyleDefault 
                                       handler:nil];
            
            [alert addAction:okAction];
            
            // Sadece modern yöntem
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
            
            // Eğer pencere bulunduysa göster
            if (topWindow && topWindow.rootViewController) {
                [topWindow.rootViewController presentViewController:alert animated:YES completion:nil];
            }
        });
    });
}
%end

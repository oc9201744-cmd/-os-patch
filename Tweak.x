#import <substrate.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// 1. Grup: Riskli ama gerekli bypasslar
%group SilentBypass

%hook AceDeviceCheck
+ (BOOL)isJailbroken { return NO; }
%end

%hook UAEMonitor
+ (void)ReportEvent:(id)arg1 { 
    // Tüm raporları susturmak yerine sadece şüpheli olanları filtrele
    if ([arg1 isKindOfClass:[NSString class]]) {
        NSString *event = (NSString *)arg1;
        if ([event containsString:@"cheat"] || [event containsString:@"bypass"] || [event containsString:@"hack"]) {
            return; 
        }
    }
    %orig; 
}
%end

%hook TssSdk
- (int)getTssSdkStatus { return 1; }
%end

%end

// 2. Grup: Lobiye girdikten sonra çalışacak UI/Mesaj kısmı
%group UILogic
%hook UnityAppController
- (void)applicationDidBecomeActive:(id)application {
    %orig;
    // Sadece lobiye girdiğinde küçük bir log bas (Görsel mesajı şimdilik kapattık ki crash yapmasın)
    NSLog(@"[AnoBypass] Tweak Aktif!");
}
%end
%end

%ctor {
    // Siyah ekranı ve Data Error'u engellemek için 25 saniye geciktirme
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(25.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        %init(SilentBypass);
        %init(UILogic);
        NSLog(@"[AnoBypass] 25 saniye doldu. Bypass sessizce enjekte edildi.");
    });
}

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// iOS app hazır olunca çalışması için
__attribute__((constructor))
static void tweak_entry() {
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
            UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
            if (!keyWindow) return;

            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, 300, 40)];
            label.text = @"✅ Dobby Hook AKTİF";
            label.textColor = [UIColor redColor];
            label.font = [UIFont boldSystemFontOfSize:18];
            label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
            label.textAlignment = NSTextAlignmentCenter;
            label.layer.cornerRadius = 8;
            label.layer.masksToBounds = YES;

            [keyWindow addSubview:label];
        }
    );
}

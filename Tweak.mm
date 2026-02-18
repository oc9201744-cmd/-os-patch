#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

// Dobby
extern "C" {
    int DobbyHook(void *function_address, void *replace_call, void **origin_call);
}

// ===============================
// ORİJİNAL FONKSİYON POINTER
// ===============================
static void (*orig_sendEvent)(UIApplication *self, SEL _cmd, UIEvent *event);

// ===============================
// EKRANA YAZI BASAN FONKSİYON
// ===============================
static void showHookLabel() {
    dispatch_async(dispatch_get_main_queue(), ^{

        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) {
            window = [UIApplication sharedApplication].windows.firstObject;
        }

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(30, 120, 320, 60)];
        label.text = @"DOBBY HOOK AKTIF";
        label.textColor = [UIColor greenColor];
        label.font = [UIFont boldSystemFontOfSize:22];
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        label.layer.cornerRadius = 12;
        label.clipsToBounds = YES;

        [window addSubview:label];
    });
}

// ===============================
// HOOK'LANAN FONKSİYON
// ===============================
static void hooked_sendEvent(UIApplication *self, SEL _cmd, UIEvent *event) {

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Hook gerçekten çalıştıktan sonra yazı bas
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC),
                       dispatch_get_main_queue(), ^{
            showHookLabel();
        });
    });

    // Orijinale geri dön
    orig_sendEvent(self, _cmd, event);
}

// ===============================
// CONSTRUCTOR (ENTRY POINT)
// ===============================
__attribute__((constructor))
static void init() {

    NSLog(@"[+] Tweak loaded, Dobby hook kuruluyor");

    Class cls = objc_getClass("UIApplication");
    Method method = class_getInstanceMethod(cls, @selector(sendEvent:));

    void *imp = (void *)method_getImplementation(method);

    if (DobbyHook(imp,
                  (void *)hooked_sendEvent,
                  (void **)&orig_sendEvent) == 0) {

        NSLog(@"[+] Dobby hook basarili");
    } else {
        NSLog(@"[-] Dobby hook basarisiz");
    }
}
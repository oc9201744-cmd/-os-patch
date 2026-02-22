#include <stdint.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <fcntl.h>
#include <string.h> // strcasestr için
#include "include/dobby.h"

void* (*orig_dlopen)(const char* path, int mode);
int (*orig_open)(const char *path, int oflag, mode_t mode);

void show_on_screen(NSString *message, CGFloat yPosition, UIColor *color) {
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect screenRect = [UIScreen mainScreen].bounds;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, yPosition, screenRect.size.width, 30)];
        label.text = message;
        label.textColor = color;
        label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:12];
        label.layer.zPosition = 9999;
        
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = ((UIWindowScene*)scene).windows.firstObject;
                    break;
                }
            }
        } else { window = [UIApplication sharedApplication].keyWindow; }
        [window addSubview:label];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [label removeFromSuperview];
        });
    });
}

// Büyük/Küçük harf duyarsız kontrol (Anogs veya anogs ikisini de yakalar)
void* fake_dlopen(const char* path, int mode) {
    if (path != NULL && strcasestr(path, "anogs")) {
        NSString *fakePath = [[NSBundle mainBundle] pathForResource:@"002" ofType:@"bin"];
        if (fakePath) {
            show_on_screen(@"[DLOPEN] ANOGS YAKALANDI -> 002.BIN", 120, [UIColor greenColor]);
            return orig_dlopen([fakePath UTF8String], mode);
        }
    }
    return orig_dlopen(path, mode);
}

int fake_open(const char *path, int oflag, mode_t mode) {
    if (path != NULL && strcasestr(path, "anogs")) {
        NSString *fakePath = [[NSBundle mainBundle] pathForResource:@"002" ofType:@"bin"];
        if (fakePath) {
            show_on_screen(@"[OPEN] ANOGS YAKALANDI -> 002.BIN", 155, [UIColor cyanColor]);
            return orig_open([fakePath UTF8String], oflag, mode);
        }
    }
    return orig_open(path, oflag, mode);
}

__attribute__((constructor))
static void deep_hook_init() {
    @autoreleasepool {
        DobbyHook((void *)dlopen, (void *)fake_dlopen, (void **)&orig_dlopen);
        DobbyHook((void *)open, (void *)fake_open, (void **)&orig_open);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            show_on_screen(@"[KINGMOD] HARF DUYARSIZ KANCA AKTIF", 50, [UIColor whiteColor]);
        });
    }
}

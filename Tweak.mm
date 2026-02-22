#include <stdint.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <fcntl.h>
#include "include/dobby.h"

// Orijinal saklayıcılar
int (*orig_open)(const char *path, int oflag, mode_t mode);

void show_on_screen(NSString *message, CGFloat yPosition, UIColor *color) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, yPosition, [UIScreen mainScreen].bounds.size.width, 25)];
        label.text = message;
        label.textColor = color;
        label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:10];
        label.layer.zPosition = 9999;
        [[UIApplication sharedApplication].keyWindow addSubview:label];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [label removeFromSuperview];
        });
    });
}

// BU KISIM TÜM TRAFİĞİ İZLER
int fake_open(const char *path, int oflag, mode_t mode) {
    if (path != NULL) {
        NSString *currentPath = [NSString stringWithUTF8String:path];
        
        // Sadece önemli gördüğümüz uzantıları ekranda gösterelim (Ekran dolmasın diye)
        if ([currentPath containsString:@"Anogs"] || [currentPath containsString:@"framework"] || [currentPath containsString:@"ShadowTracker"]) {
            show_on_screen([NSString stringWithFormat:@"AÇILAN: %@", [currentPath lastPathComponent]], 100 + (arc4random() % 100), [UIColor orangeColor]);
        }

        // EĞER YAKALARSAK YÖNLENDİR
        if ([currentPath.lowercaseString containsString:@"anogs"]) {
            NSString *fakePath = [[NSBundle mainBundle] pathForResource:@"002" ofType:@"bin"];
            if (fakePath) {
                show_on_screen(@"!!! 002.BIN DEVREYE GİRDİ !!!", 70, [UIColor greenColor]);
                return orig_open([fakePath UTF8String], oflag, mode);
            }
        }
    }
    return orig_open(path, oflag, mode);
}

__attribute__((constructor))
static void scanner_init() {
    @autoreleasepool {
        DobbyHook((void *)open, (void *)fake_open, (void **)&orig_open);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            show_on_screen(@"[KINGMOD] SCANNER MODU AKTIF", 40, [UIColor whiteColor]);
        });
    }
}

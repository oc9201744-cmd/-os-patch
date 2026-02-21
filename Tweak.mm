#include <mach-o/dyld.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>

#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>
#include <string.h>

static BOOL anogsFound = NO;

static void check_anogs(void) {
    if (anogsFound) return;

    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "anogs")) {
            anogsFound = YES;

            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alert =
                [UIAlertController alertControllerWithTitle:@"OK"
                                                     message:@"anogs yüklendi"
                                              preferredStyle:UIAlertControllerStyleAlert];
                [[UIApplication sharedApplication].keyWindow.rootViewController
                 presentViewController:alert animated:YES completion:nil];
            });
            return;
        }
    }
}

__attribute__((constructor))
static void entry() {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (!anogsFound) {
            check_anogs();
            sleep(3);
        }
    });
}

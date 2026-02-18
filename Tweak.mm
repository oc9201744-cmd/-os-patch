#import <Foundation/Foundation.h>
#include "dobby.h"

void (*orig_NSLog)(NSString *format, ...);

void my_NSLog(NSString *format, ...) {
    orig_NSLog(@"[HOOKED] %@", format);
}

__attribute__((constructor))
static void init() {
    DobbyHook(
        (void *)NSLog,
        (void *)my_NSLog,
        (void **)&orig_NSLog
    );
}
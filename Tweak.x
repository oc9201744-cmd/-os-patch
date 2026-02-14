__attribute__((constructor))
static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(45.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
        if (slide == 0) {
            NSLog(@"[Gemini] Uyarı: Slide 0 geldi, ASLR kapalı mı?");
        }
        
        void *base = (void *)(slide + 0x100000000ULL); // bazen base 0x100000000 kabul edilir, dene
        
        MSHookFunction((void *)(slide + 0xF012C),   (void *)hook_sub_F012C,   (void **)&orig_sub_F012C);
        MSHookFunction((void *)(slide + 0xF838C),   (void *)hook_sub_F838C,   (void **)&orig_sub_F838C);
        MSHookFunction((void *)(slide + 0x11D85C),  (void *)hook_sub_11D85C,  (void **)&orig_sub_11D85C);
        
        NSLog(@"[Gemini] Hook adresleri → F012C: %p", (void*)(slide + 0xF012C));
        
        // ... kalan UIAlertController kısmı aynı kalabilir
    });
}
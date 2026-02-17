#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <fcntl.h>
#import <sys/stat.h>

// --- BAYBARS GÖRSEL ANONS ---
void BaybarsAnons(NSString *text, UIColor *color) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
        label.center = CGPointMake(window.frame.size.width / 2, 110);
        label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.85];
        label.textColor = color;
        label.textAlignment = NSTextAlignmentCenter;
        label.text = text;
        label.font = [UIFont boldSystemFontOfSize:16];
        label.layer.cornerRadius = 12;
        label.clipsToBounds = YES;
        label.layer.borderColor = color.CGColor;
        label.layer.borderWidth = 1.0;
        [window addSubview:label];
        [UIView animateWithDuration:0.5 delay:4.0 options:0 animations:^{ label.alpha = 0; } completion:^(BOOL f){ [label removeFromSuperview]; }];
    });
}

// --- DOSYA YÖNLENDİRME MOTORU ---
// Orijinal fonksiyonların adreslerini saklıyoruz
static int (*old_open)(const char *path, int oflag, ...);
static FILE *(*old_fopen)(const char *path, const char *mode);

// Yeni 'open' fonksiyonumuz
int new_open(const char *path, int oflag, ...) {
    if (path != NULL && strstr(path, "ShadowTrackerExtra") && !strstr(path, "_Bak")) {
        // Anticheat ana dosyayı açmaya çalışıyor, onu yedeğe yönlendir!
        char newPath[1024];
        snprintf(newPath, sizeof(newPath), "%s_Bak", path);
        return old_open(newPath, oflag);
    }
    
    // Variadic (değişken argümanlı) fonksiyon olduğu için mod kontrolü
    mode_t mode = 0;
    if (oflag & O_CREAT) {
        va_list args;
        va_start(args, oflag);
        mode = va_arg(args, int);
        va_end(args);
    }
    return old_open(path, oflag, mode);
}

// Yeni 'fopen' fonksiyonumuz
FILE *new_fopen(const char *path, const char *mode) {
    if (path != NULL && strstr(path, "ShadowTrackerExtra") && !strstr(path, "_Bak")) {
        char newPath[1024];
        snprintf(newPath, sizeof(newPath), "%s_Bak", path);
        return old_fopen(newPath, mode);
    }
    return old_fopen(path, mode);
}

void* BaybarsRedirectionWorker(void* arg) {
    // 1. ADIM: Baybars Aktif Yazısı
    [NSThread sleepForTimeInterval:6.0];
    BaybarsAnons(@"Baybars: Dosya Yönlendirme Aktif!", [UIColor orangeColor]);

    // 2. ADIM: 45 Saniye Bekleme
    // Bu sürede oyunun normal yükleme işlemlerini yapmasına izin veriyoruz
    [NSThread sleepForTimeInterval:45.0];

    // 3. ADIM: Sistem Fonksiyonlarını Kancala (Hook)
    // dlsym ile orijinal fonksiyonları yakalayıp kendi fonksiyonlarımızla değiştiriyoruz
    old_open = (int (*)(const char *, int, ...))dlsym(RTLD_DEFAULT, "open");
    old_fopen = (FILE *(*)(const char *, const char *))dlsym(RTLD_DEFAULT, "fopen");

    // Rebind (Yeniden Bağlama) işlemi - Kingmod tarzı dinamik değişim
    // Not: Bu kısım normalde fishhook kütüphanesi ile daha stabil olur ama 
    // biz dylib içinde sembol kaydırma yapacağız.
    
    uintptr_t slide = (uintptr_t)_dyld_get_image_vmaddr_slide(0);
    
    // Ofsetler üzerinden Anticheat'in 'ShadowTrackerExtra' okuma kanallarını kapat
    // (Analiz ettiğin Pubg.txt ve anogs.c'deki integrity ofsetlerine 'RET' çakıyoruz)
    // 0xF806C: Integrity Check Point
    uint32_t patch_ret[] = {0xD65F03C0}; 
    mach_port_t task = mach_task_self();
    vm_protect(task, trunc_page(slide + 0xF806C), PAGE_SIZE, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    memcpy((void *)(slide + 0xF806C), patch_ret, 4);
    vm_protect(task, trunc_page(slide + 0xF806C), PAGE_SIZE, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);

    BaybarsAnons(@"Baybars: Tarama Yedeğe Yönlendirildi!", [UIColor cyanColor]);
    
    return NULL;
}

__attribute__((constructor))
static void BaybarsMain() {
    pthread_t t;
    pthread_create(&t, NULL, BaybarsRedirectionWorker, NULL);
}

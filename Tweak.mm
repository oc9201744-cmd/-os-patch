#import <substrate.h>
#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <mach-o/loader.h>
#import <mach-o/dyld.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import <zlib.h>

// MARK: - File Operations Hooks
static FILE* (*orig_fopen)(const char *filename, const char *mode);
FILE* hook_fopen(const char *filename, const char *mode) {
    // Eğer kontrol edilen dosya uygulama içindeyse ve bütünlük kontrolü için açılıyorsa
    // gerçek dosya yerine beklenen içeriği içeren bir dosya döndürebiliriz.
    // Ancak bu karmaşık. Şimdilik sadece orijinal fopen'ı çağıralım.
    return orig_fopen(filename, mode);
}

static size_t (*orig_fread)(void *ptr, size_t size, size_t nmemb, FILE *stream);
size_t hook_fread(void *ptr, size_t size, size_t nmemb, FILE *stream) {
    // Okunan veriyi değiştirebiliriz.
    return orig_fread(ptr, size, nmemb, stream);
}

// MARK: - String Comparison Hooks (strcmp, memcmp, etc.)
static int (*orig_strcmp)(const char *s1, const char *s2);
int hook_strcmp(const char *s1, const char *s2) {
    // Eğer karşılaştırılan string'lerden biri beklenen hash/imza ise
    // 0 döndürerek eşit olduğunu söyleyebiliriz.
    // Örneğin: if (strstr(s2, "expected_signature")) return 0;
    return orig_strcmp(s1, s2);
}

static int (*orig_memcmp)(const void *s1, const void *s2, size_t n);
int hook_memcmp(const void *s1, const void *s2, size_t n) {
    // Aynı şekilde bellekte karşılaştırma yapılıyorsa eşit olduğunu söyle.
    return orig_memcmp(s1, s2, n);
}

// MARK: - CRC32 Hooks (zlib)
static uLong (*orig_crc32)(uLong crc, const Bytef *buf, uInt len);
uLong hook_crc32(uLong crc, const Bytef *buf, uInt len) {
    // CRC32 hesaplamasını intercept et. Gerçek hesaplama yerine sabit bir değer döndürebiliriz.
    // Ancak bu kontrolleri bozabilir. Daha iyisi: orijinal hesaplamayı yap ama sonucu değiştirme.
    // Eğer belirli bir buffer için beklenen crc'yi biliyorsak onu döndürebiliriz.
    return orig_crc32(crc, buf, len);
}

// MARK: - SHA/HMAC Hooks (CommonCrypto)
static int (*orig_CC_SHA256)(const void *data, CC_LONG len, unsigned char *md);
int hook_CC_SHA256(const void *data, CC_LONG len, unsigned char *md) {
    // SHA256 hesaplamasını intercept et.
    return orig_CC_SHA256(data, len, md);
}

static int (*orig_CC_SHA256_Init)(CC_SHA256_CTX *c);
int hook_CC_SHA256_Init(CC_SHA256_CTX *c) {
    return orig_CC_SHA256_Init(c);
}

static int (*orig_CC_SHA256_Update)(CC_SHA256_CTX *c, const void *data, CC_LONG len);
int hook_CC_SHA256_Update(CC_SHA256_CTX *c, const void *data, CC_LONG len) {
    return orig_CC_SHA256_Update(c, data, len);
}

static int (*orig_CC_SHA256_Final)(unsigned char *md, CC_SHA256_CTX *c);
int hook_CC_SHA256_Final(unsigned char *md, CC_SHA256_CTX *c) {
    return orig_CC_SHA256_Final(md, c);
}

// MARK: - DYLD Info Hooks (image count, name, etc.)
static uint32_t (*orig__dyld_image_count)(void);
uint32_t hook__dyld_image_count(void) {
    // Tweak'lerin yüklenmesini gizlemek için sayıyı azaltabiliriz.
    uint32_t count = orig__dyld_image_count();
    // Burada uygulama dışındaki kütüphaneleri saymamak için filtreleme yapabiliriz.
    return count;
}

static const char* (*orig__dyld_get_image_name)(uint32_t image_index);
const char* hook__dyld_get_image_name(uint32_t image_index) {
    const char *name = orig__dyld_get_image_name(image_index);
    // Eğer isim "Tweak" veya "Substrate" içeriyorsa, farklı bir isim döndürebiliriz.
    if (name && (strstr(name, "Tweak") || strstr(name, "Substrate") || strstr(name, "Cydia"))) {
        return "";
    }
    return name;
}

// MARK: - Ptrace Hook (anti-debug)
static int (*orig_ptrace)(int request, pid_t pid, caddr_t addr, int data);
int hook_ptrace(int request, pid_t pid, caddr_t addr, int data) {
    if (request == 31) { // PT_DENY_ATTACH
        return 0; // Başarısız olmasını sağla
    }
    return orig_ptrace(request, pid, addr, data);
}

// MARK: - sysctl Hook (anti-debug)
static int (*orig_sysctl)(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen);
int hook_sysctl(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    // Eğer sorgu KERN_PROC içeriyorsa ve P_TRACED flag'ini temizle
    if (namelen == 4 && name[0] == CTL_KERN && name[1] == KERN_PROC && name[2] == KERN_PROC_PID) {
        int ret = orig_sysctl(name, namelen, oldp, oldlenp, newp, newlen);
        if (ret == 0 && oldp) {
            struct kinfo_proc *proc = (struct kinfo_proc *)oldp;
            proc->kp_proc.p_flag &= ~P_TRACED; // Debug flag'ini kaldır
        }
        return ret;
    }
    return orig_sysctl(name, namelen, oldp, oldlenp, newp, newlen);
}

// MARK: - Constructor
%ctor {
    @autoreleasepool {
        // File operations
        MSHookFunction((void *)fopen, (void *)hook_fopen, (void **)&orig_fopen);
        MSHookFunction((void *)fread, (void *)hook_fread, (void **)&orig_fread);
        
        // String comparisons
        MSHookFunction((void *)strcmp, (void *)hook_strcmp, (void **)&orig_strcmp);
        MSHookFunction((void *)memcmp, (void *)hook_memcmp, (void **)&orig_memcmp);
        
        // CRC32
        MSHookFunction((void *)crc32, (void *)hook_crc32, (void **)&orig_crc32);
        
        // SHA256 (CommonCrypto)
        void *handle = dlopen("/usr/lib/system/libcommonCrypto.dylib", RTLD_LAZY);
        if (handle) {
            MSHookFunction((void *)dlsym(handle, "CC_SHA256"), (void *)hook_CC_SHA256, (void **)&orig_CC_SHA256);
            MSHookFunction((void *)dlsym(handle, "CC_SHA256_Init"), (void *)hook_CC_SHA256_Init, (void **)&orig_CC_SHA256_Init);
            MSHookFunction((void *)dlsym(handle, "CC_SHA256_Update"), (void *)hook_CC_SHA256_Update, (void **)&orig_CC_SHA256_Update);
            MSHookFunction((void *)dlsym(handle, "CC_SHA256_Final"), (void *)hook_CC_SHA256_Final, (void **)&orig_CC_SHA256_Final);
            dlclose(handle);
        }
        
        // DYLD
        MSHookFunction((void *)_dyld_image_count, (void *)hook__dyld_image_count, (void **)&orig__dyld_image_count);
        MSHookFunction((void *)_dyld_get_image_name, (void *)hook__dyld_get_image_name, (void **)&orig__dyld_get_image_name);
        
        // Anti-debug
        MSHookFunction((void *)ptrace, (void *)hook_ptrace, (void **)&orig_ptrace);
        MSHookFunction((void *)sysctl, (void *)hook_sysctl, (void **)&orig_sysctl);
        
        NSLog(@"[Tweak] Integrity bypass hooks loaded.");
    }
}
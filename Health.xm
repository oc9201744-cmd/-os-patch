#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import <pthread.h>

// Kingmod'un kullandığı profesyonel bellek yamalayıcı (Integrity Bypass)
void SafeKingPatch(uintptr_t address, uint32_t patch_hex) {
    mach_port_t task = mach_task_self();
    vm_address_t page_start = trunc_page(address);
    
    // Bellek sayfasını yazılabilir yap (Copy-on-Write)
    kern_return_t kr = vm_protect(task, page_start, PAGE_SIZE, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    
    if (kr == KERN_SUCCESS) {
        *(uint32_t *)address = patch_hex;
        // Korumayı geri yükle (ACE taramasına takılmamak için)
        vm_protect(task, page_start, PAGE_SIZE, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    }
}

// Arka plan thread'i: Oyunun açılışını engellemez, siyah ekran yapmaz.
void* BypassWorker(void* arg) {
    // Oyunun tüm kontrollerini geçmesi için 25 saniye pusuya yatıyoruz
    [NSThread sleepForTimeInterval:25.0];

    // ASLR Kaymasını (Base Address) al
    uintptr_t base = (uintptr_t)_dyld_get_image_vmaddr_slide(0);
    
    // bak 6.txt ofsetleri: 0xF806C ve 0xF80A8
    // Bu adresleri sessizce 'RET' (0xD65F03C0) ile kapatıyoruz
    SafeKingPatch(base + 0xF806C, 0xD65F03C0); 
    SafeKingPatch(base + 0xF80A8, 0xD65F03C0);
    
    return NULL;
}

// Kütüphane Girişi
__attribute__((constructor))
static void MainInit() {
    // Ana akışı bozmamak için hemen yeni bir thread oluşturuyoruz (Kingmod Sistemi)
    pthread_t thread;
    pthread_create(&thread, NULL, BypassWorker, NULL);
}

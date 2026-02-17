#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import <pthread.h>

// --- KINGMOD STİLİ MEMORY YAZICI ---
// Bu fonksiyon, hafızayı zorla RWX (Okunabilir, Yazılabilir, Çalıştırılabilir) yapar
void KingmodPatch(uintptr_t address, uint32_t data) {
    mach_port_t task = mach_task_self();
    vm_address_t page_start = trunc_page(address);
    vm_size_t page_size = PAGE_SIZE;

    // Hafıza korumasını kaldır (Kingmod'un en büyük sırrı)
    if (vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY) == KERN_SUCCESS) {
        *(uint32_t *)address = data;
        // İzi temizle: Orijinal hale getir (Sadece Oku ve Çalıştır)
        vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    }
}

// --- BAYBARS GÖRSEL ANONS ---
void BaybarsAnons(NSString *text, UIColor *textCol) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 50)];
        UIWindow *win = [[UIApplication sharedApplication] keyWindow];
        label.center = CGPointMake(win.frame.size.width / 2, 100);
        label.text = text;
        label.textColor = textCol;
        label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:17];
        label.layer.cornerRadius = 15;
        label.clipsToBounds = YES;
        [win addSubview:label];

        [UIView animateWithDuration:0.8 delay:4.0 options:0 animations:^{ label.alpha = 0; } completion:^(BOOL f){ [label removeFromSuperview]; }];
    });
}

void* BaybarsKingThread(void* arg) {
    // 1. ADIM: Başlangıç Anonsu
    [NSThread sleepForTimeInterval:7.0];
    BaybarsAnons(@"Baybars Aktif Oldu!", [UIColor cyanColor]);

    // 2. ADIM: 45 Saniye Bekleme (Kingmod Gecikmesi)
    // ACE'nin ilk "Integrity Check" (Hafıza taraması) dalgasını bitirmesini bekliyoruz.
    [NSThread sleepForTimeInterval:45.0];

    uintptr_t slide = (uintptr_t)_dyld_get_image_vmaddr_slide(0);

    // --- 3. ADIM: DOSYA ANALİZİNDEN GELEN ANTICHEAT SUSTURUCULAR ---

    // [AnoSDK] Raporlamayı durdur (Pubg.txt: _AnoSDKOnRecvSignature_0)
    // Ofset: 0x2DF68 -> RET (Her şeyi kabul et ama cevap verme)
    KingmodPatch(slide + 0x2DF68, 0xD65F03C0);

    // [Integrity] Hafıza taraması yapan ana döngüyü kır
    // Ofset: 0xF806C -> MOV W0, #0 ; RET (Sorun yok dedirtmek)
    KingmodPatch(slide + 0xF806C, 0x52800000); 
    KingmodPatch(slide + 0xF806C + 4, 0xD65F03C0);

    // [TssSDK] Analiz dosyasındaki gizli tarama noktası (sub_D1D08 benzeri)
    // Ofset: 0xF80A8 -> RET
    KingmodPatch(slide + 0xF80A8, 0xD65F03C0);

    // [Security] Cihaz kimlik toplama rutinini boz (sub_36A9C)
    KingmodPatch(slide + 0x36A9C, 0xD65F03C0);

    // 4. ADIM: Final Anonsu
    BaybarsAnons(@"Anticheat Devre Dışı!", [UIColor limeColor]);
    
    return NULL;
}

__attribute__((constructor))
static void BaybarsEntry() {
    pthread_t t;
    pthread_create(&t, NULL, BaybarsKingThread, NULL);
}

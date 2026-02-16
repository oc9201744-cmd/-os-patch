#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <string.h>
#include <stdlib.h>

// --- FISHHOOK MİNİMAL MOTORU (HATALAR DÜZELTİLDİ) ---

typedef struct rebinding {
  const char *name;
  void *replacement;
  void **replaced;
} rebinding;

struct rebindings_entry {
  struct rebindings_entry *next;
  unsigned int rebindings_nel;
  rebinding *rebindings;
};

static struct rebindings_entry *_rebindings_head;

static int prepend_rebindings(struct rebindings_entry **rebindings_head,
                              rebinding *rebindings,
                              size_t nel) {
  struct rebindings_entry *new_entry = (struct rebindings_entry *)malloc(sizeof(struct rebindings_entry));
  if (!new_entry) return -1;
  new_entry->rebindings = (rebinding *)malloc(sizeof(rebinding) * nel);
  if (!new_entry->rebindings) { free(new_entry); return -1; }
  memcpy(new_entry->rebindings, rebindings, sizeof(rebinding) * nel);
  new_entry->rebindings_nel = (unsigned int)nel;
  new_entry->next = *rebindings_head;
  *rebindings_head = new_entry;
  return 0;
}

static void perform_rebinding_with_section(struct rebindings_entry *rebindings,
                                           const struct section_64 *section,
                                           intptr_t slide,
                                           struct nlist_64 *symtab,
                                           char *strtab,
                                           uint32_t *indirect_symtab) {
  uint32_t *indirect_symbol_indices = indirect_symtab + section->reserved1;
  void **indirect_symbol_bindings = (void **)((uintptr_t)slide + section->addr);
  for (uint32_t i = 0; i < section->size / sizeof(void *); i++) {
    uint32_t symtab_index = indirect_symbol_indices[i];
    if (symtab_index == INDIRECT_SYMBOL_ABS || symtab_index == INDIRECT_SYMBOL_LOCAL ||
        symtab_index == (INDIRECT_SYMBOL_LOCAL | INDIRECT_SYMBOL_ABS)) continue;
    uint32_t strtab_offset = symtab[symtab_index].n_un.n_strx;
    char *symbol_name = strtab + strtab_offset;
    if (strnlen(symbol_name, 2) < 2) continue;
    struct rebindings_entry *cur = rebindings;
    while (cur) {
      for (uint32_t j = 0; j < cur->rebindings_nel; j++) {
        if (strcmp(&symbol_name[1], cur->rebindings[j].name) == 0) {
          if (cur->rebindings[j].replaced != NULL &&
              indirect_symbol_bindings[i] != cur->rebindings[j].replacement) {
            *(cur->rebindings[j].replaced) = indirect_symbol_bindings[i];
          }
          indirect_symbol_bindings[i] = cur->rebindings[j].replacement;
          goto symbol_loop;
        }
      }
      cur = cur->next;
    }
  symbol_loop:;
  }
}

static void rebind_symbols_image(const struct mach_header_64 *header,
                                 intptr_t slide) {
  Dl_info info;
  if (dladdr(header, &info) == 0) return;
  struct segment_command_64 *cur_seg_cmd;
  struct segment_command_64 *linkedit_segment = NULL;
  struct symtab_command* symtab_cmd = NULL;
  struct dysymtab_command* dysymtab_cmd = NULL;
  cur_seg_cmd = (struct segment_command_64 *)((uintptr_t)header + sizeof(struct mach_header_64));
  for (uint32_t i = 0; i < header->ncmds; i++, cur_seg_cmd = (struct segment_command_64 *)((uintptr_t)cur_seg_cmd + cur_seg_cmd->cmdsize)) {
    if (cur_seg_cmd->cmd == LC_SEGMENT_64) {
      if (strcmp(cur_seg_cmd->segname, "__LINKEDIT") == 0) linkedit_segment = cur_seg_cmd;
    } else if (cur_seg_cmd->cmd == LC_SYMTAB) {
      symtab_cmd = (struct symtab_command*)cur_seg_cmd;
    } else if (cur_seg_cmd->cmd == LC_DYSYMTAB) {
      dysymtab_cmd = (struct dysymtab_command*)cur_seg_cmd;
    }
  }
  if (!symtab_cmd || !dysymtab_cmd || !linkedit_segment || !dysymtab_cmd->nindirectsyms) return;
  uintptr_t linkedit_base = (uintptr_t)slide + linkedit_segment->vmaddr - linkedit_segment->fileoff;
  struct nlist_64 *symtab = (struct nlist_64 *)(linkedit_base + symtab_cmd->symoff);
  char *strtab = (char *)(linkedit_base + symtab_cmd->stroff);
  uint32_t *indirect_symtab = (uint32_t *)(linkedit_base + dysymtab_cmd->indirectsymoff);
  cur_seg_cmd = (struct segment_command_64 *)((uintptr_t)header + sizeof(struct mach_header_64));
  for (uint32_t i = 0; i < header->ncmds; i++, cur_seg_cmd = (struct segment_command_64 *)((uintptr_t)cur_seg_cmd + cur_seg_cmd->cmdsize)) {
    if (cur_seg_cmd->cmd == LC_SEGMENT_64 && (strcmp(cur_seg_cmd->segname, "__DATA_CONST") == 0 || strcmp(cur_seg_cmd->segname, "__DATA") == 0)) {
      for (uint32_t j = 0; j < cur_seg_cmd->nsects; j++) {
        struct section_64 *sect = (struct section_64 *)((uintptr_t)cur_seg_cmd + sizeof(struct segment_command_64)) + j;
        if ((sect->flags & SECTION_TYPE) == S_LAZY_SYMBOL_POINTERS || (sect->flags & SECTION_TYPE) == S_NON_LAZY_SYMBOL_POINTERS) {
          perform_rebinding_with_section(_rebindings_head, sect, slide, symtab, strtab, indirect_symtab);
        }
      }
    }
  }
}

static void rebind_symbols(rebinding rebindings[], size_t rebindings_nel) {
  prepend_rebindings(&_rebindings_head, rebindings, rebindings_nel);
  uint32_t count = _dyld_image_count();
  for (uint32_t i = 0; i < count; i++) {
    rebind_symbols_image((const struct mach_header_64 *)_dyld_get_image_header(i), _dyld_get_image_vmaddr_slide(i));
  }
}

// --- BYPASS MANTIĞI ---

static void* (*orig_GetReport)(int);
void* my_GetReport(int a) { return NULL; }

static void (*orig_DelReport)(void*);
void my_DelReport(void* a) { return; }

static int (*orig_Ioctl)(int, void*, int);
int my_Ioctl(int a, void* b, int c) { return 0; }

// --- UI ---
void show_v20_label() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        }
        if (!window) window = [UIApplication sharedApplication].windows.firstObject;

        if (window) {
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, window.frame.size.width, 20)];
            lbl.text = @"🛡️ ONUR CAN: FISHHOOK V20 ACTIVE ✅";
            lbl.textColor = [UIColor cyanColor];
            lbl.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.font = [UIFont boldSystemFontOfSize:10];
            [window addSubview:lbl];
        }
    });
}

// --- CONSTRUCTOR ---
__attribute__((constructor))
static void initialize() {
    rebinding bindings[] = {
        {"AnoSDKGetReportData", (void *)my_GetReport, (void **)&orig_GetReport},
        {"AnoSDKDelReportData", (void *)my_DelReport, (void **)&orig_DelReport},
        {"AnoSDKIoctl", (void *)my_Ioctl, (void **)&orig_Ioctl}
    };
    
    rebind_symbols(bindings, 3);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        show_v20_label();
    });
}

if (strcmp(cur_seg_cmd->segname, SEG_DATA) != 0 &&
                strcmp(cur_seg_cmd->segname, SEG_DATA_CONST) != 0) {
                continue;
            }
            for (size_t j = 0; j < cur_seg_cmd->nsects; j++) {
                section_t *sect = (section_t *)((uintptr_t)cur + sizeof(segment_command_t) + j * sizeof(section_t));
                if ((sect->flags & SECTION_TYPE) == S_LAZY_SYMBOL_POINTERS) {
                    perform_rebinding_with_section(entry, sect, slide, symtab, strtab, indirect_symtab);
                }
                if ((sect->flags & SECTION_TYPE) == S_NON_LAZY_SYMBOL_POINTERS) {
                    perform_rebinding_with_section(entry, sect, slide, symtab, strtab, indirect_symtab);
                }
            }
        }
    }
}

int rebind_symbols_image(void *header,
                         intptr_t slide,
                         struct rebinding rebindings[],
                         size_t rebindings_nel) {
    struct rebindings_entry *new_entry = (struct rebindings_entry *)malloc(sizeof(struct rebindings_entry));
    if (!new_entry) return -1;
    
    new_entry->rebindings = (struct rebinding *)malloc(sizeof(struct rebinding) * rebindings_nel);
    if (!new_entry->rebindings) {
        free(new_entry);
        return -1;
    }
    memcpy(new_entry->rebindings, rebindings, sizeof(struct rebinding) * rebindings_nel);
    new_entry->rebindings_nel = rebindings_nel;
    new_entry->next = rebindings_head;
    rebindings_head = new_entry;
    
    rebind_symbols_for_image(new_entry, (const mach_header_t *)header, slide);
    return 0;
}

int rebind_symbols(struct rebinding rebindings[], size_t rebindings_nel) {
    int retval = 0;
    
    // 先記錄下來，用於後續加載的 image
    struct rebindings_entry *new_entry = (struct rebindings_entry *)malloc(sizeof(struct rebindings_entry));
    if (!new_entry) return -1;
    new_entry->rebindings = (struct rebinding *)malloc(sizeof(struct rebinding) * rebindings_nel);
    if (!new_entry->rebindings) {
        free(new_entry);
        return -1;
    }
    memcpy(new_entry->rebindings, rebindings, sizeof(struct rebinding) * rebindings_nel);
    new_entry->rebindings_nel = rebindings_nel;
    new_entry->next = rebindings_head;
    rebindings_head = new_entry;
    
    // 對目前已加載的所有 image 進行重定
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const mach_header_t *header = (const mach_header_t *)_dyld_get_image_header(i);
        intptr_t slide = _dyld_get_image_vmaddr_slide(i);
        rebind_symbols_for_image(new_entry, header, slide);
    }
    
    return retval;
}

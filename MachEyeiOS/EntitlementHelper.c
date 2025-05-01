//
//  EntitlementHelper.m
//  PrivateAPI_TEST
//
//  Created by Aryan Rogye on 4/29/25.
//

#import "EntitlementHelper.h"
#include <mach-o/nlist.h>
#include <mach-o/dyld.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <dlfcn.h>
#include <string.h>

const char *getLastPathComponent(const char *path) {
    const char *lastSlash = strrchr(path, '/');
    if (lastSlash) {
        return lastSlash + 1; // move past the '/'
    } else {
        return path; // no slash found, return original
    }
}

int isTaskForPidAllowed(void) {
    mach_port_t task;
    kern_return_t result = task_for_pid(mach_task_self(), getpid(), &task);
    return (result == KERN_SUCCESS);
}

int canLoadDylib(const char* path) {
    char fullPath[512];
    snprintf(fullPath, sizeof(fullPath),
             "/System/Library/PrivateFrameworks/%s/%.*s",
             path,
             (int)(strlen(path) - strlen(".framework")),
             path);
    void *handle = dlopen(fullPath, RTLD_LAZY);
    if (handle) {
        dlclose(handle);
        return 1;
    }
    return 0;
}

int canLoadDylibABS(const char* path) {
    void *handle = dlopen(path, RTLD_LAZY);
    if (handle) {
        dlclose(handle);
        return 1;
    }
    return 0;
}


char** get_loaded_binaries_via_memory(int *count_out) {
    uint32_t count = _dyld_image_count();
    char **binaries = malloc(count * sizeof(char *));
    if (!binaries) return NULL;
    
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name) {
            binaries[i] = strdup(name);
        } else {
            binaries[i] = NULL;
        }
    }
    if (count_out) *count_out = count;
    return binaries;
}

LoadedImageInfo_C* openDylibABS(const char* path, int *outCount) {
    /// Get the component
    const char *component = getLastPathComponent(path);
    uint32_t image_count = _dyld_image_count();
    LoadedImageInfo_C* imageInfo = calloc(image_count, sizeof(LoadedImageInfo_C));
    
    int found = 0;
    
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *imageName = _dyld_get_image_name(i);
        if (strstr(imageName, component)) {
            const struct mach_header *header = _dyld_get_image_header(i);
            intptr_t slide = _dyld_get_image_vmaddr_slide(i);
            imageInfo[found++] = (LoadedImageInfo_C){imageName, header, slide};
        }
    }
    
    *outCount = found;
    printf("Count: %d\n", *outCount);
    return imageInfo;
}

char** getLibFunctions(const struct mach_header_64* header, intptr_t slide, int* outCount) {
    const uint8_t* ptr = (const uint8_t*)(header + 1);
    uint32_t ncmds = header->ncmds;

    int capacity = 32;
    int count = 0;
    char** result = (char**)malloc(sizeof(char*) * capacity);
    
    const struct symtab_command *symtab = NULL;

    for (uint32_t i = 0; i < ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)ptr;

        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd;

            const struct section_64* sections = (const struct section_64*)(seg + 1);
            for (uint32_t j = 0; j < seg->nsects; j++) {
                const struct section_64* sect = &sections[j];

                char buffer[256];
                snprintf(buffer, sizeof(buffer), "%s: 0x%llx – 0x%llx",
                         sect->sectname,
                         sect->addr + slide,
                         sect->addr + slide + sect->size);

                if (count >= capacity) {
                    capacity *= 2;
                    result = (char**)realloc(result, sizeof(char*) * capacity);
                }

                result[count++] = strdup(buffer);
            }
        } else if (cmd->cmd == LC_SYMTAB) {
        // LC_SYMTAB: offsets for
        //      symoff: offset to the symbol table
        //      nsyms: number of symbols
        //      stroff: offset to the string table
        //      strsize: size of the string table
            symtab = (const struct symtab_command *)cmd;
        }
        ptr += cmd->cmdsize;
    }
    
    /// Once the LC_SYMTAB has the SymTab we can get the metadata
    if (symtab) {
        const struct nlist_64 *symTable = (const struct nlist_64 *)((const uint8_t *)header + symtab->symoff);
        const char *strTable = (const char *)((const uint8_t *)header + symtab->stroff);
        
        for (uint32_t i = 0; i < symtab->nsyms; i++) {
            const struct nlist_64 *sym = &symTable[i];
            
            uint32_t strx = sym->n_un.n_strx;

            // Protect against out-of-bounds read
            if (strx >= symtab->strsize) {
                printf("❌ Skipping invalid strx %u\n", strx);
                continue;
            }

            const char *name = strTable + strx;

            // Now it's safe to access name[0]
            if (name[0] == '\0') continue;
            
            if ((sym->n_type & N_TYPE) == N_SECT && (sym->n_type & N_EXT)) {
                if (count >= capacity) {
                    printf("💥 Reallocating at count = %d, capacity = %d\n", count, capacity);
                    capacity *= 2;
                    result = (char **)realloc(result, sizeof(char *) * capacity);
                    if (!result) return NULL;
                }
                result[count++] = strdup(name);
            }
        }
    }

    *outCount = count;
    return result;
}

char** getMachOBinary(const char* path, int* outCount) {
    FILE* file = fopen(path, "rb");
    if (!file) {
        *outCount = 0;
        printf("Invalid File: %s\n", path);
        return NULL;
    }

    fseek(file, 0, SEEK_END);
    long size = ftell(file);
    rewind(file);

    char* buffer = malloc(size + 1);
    if (!buffer) {
        fclose(file);
        *outCount = 0;
        return NULL;
    }

    fread(buffer, 1, size, file);
    buffer[size] = '\0'; // null-terminate for safety

    fclose(file);

    char** result = malloc(sizeof(char*));
    result[0] = buffer;
    *outCount = 1;

    return result;
}

//
//  EntitlementHelper.m
//  PrivateAPI_TEST
//
//  Created by Aryan Rogye on 4/29/25.
//

#import "EntitlementHelper.h"
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
    snprintf(fullPath, sizeof(fullPath), "/System/Library/PrivateFrameworks/%s", path);
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


LoadedImageInfo* openDylibABS(const char* path, int *outCount) {
//    printf("Called Open Libs\n");
//    /// Open the Path
//    void* handle = dlopen(path, RTLD_NOW);
//    
//    if (handle) {
//        dlclose(handle);
//        printf("Couldnt Open Lib\n");
//        return NULL;
//    }
    /// Get the component
    const char *component = getLastPathComponent(path);
    uint32_t image_count = _dyld_image_count();
    LoadedImageInfo* imageInfo = calloc(image_count, sizeof(LoadedImageInfo));
    
    int found = 0;
    
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *imageName = _dyld_get_image_name(i);
        if (strstr(imageName, component)) {
            const struct mach_header *header = _dyld_get_image_header(i);
            intptr_t slide = _dyld_get_image_vmaddr_slide(i);
            imageInfo[found++] = (LoadedImageInfo){imageName, header, slide};
        }
    }
    
    *outCount = found;
    printf("Count: %d\n", *outCount);
    return imageInfo;
}

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

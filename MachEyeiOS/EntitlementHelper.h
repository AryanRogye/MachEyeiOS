//
//  EntitlementHelper.h
//  PrivateAPI_TEST
//
//  Created by Aryan Rogye on 4/29/25.
//

#ifndef EntitlementUtils_h
#define EntitlementUtils_h

#include <mach/mach.h>

typedef struct {
    const char *image_name;
    const struct mach_header *header;
    intptr_t slide;
} LoadedImageInfo_C;

const char *getLastPathComponent(const char *path);

int isTaskForPidAllowed(void);
int canLoadDylib(const char* path);
int canLoadDylibABS(const char* path);
char** get_loaded_binaries_via_memory(int *count_out);

LoadedImageInfo_C* openDylibABS(const char* path, int *outCount);
char** getLibFunctions(const struct mach_header_64* header, intptr_t slide, int* outCount);

#endif

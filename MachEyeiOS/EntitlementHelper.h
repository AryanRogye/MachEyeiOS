//
//  EntitlementHelper.h
//  PrivateAPI_TEST
//
//  Created by Aryan Rogye on 4/29/25.
//

#ifndef EntitlementUtils_h
#define EntitlementUtils_h

#include <mach/mach.h>

int isTaskForPidAllowed(void);
int canLoadDylib(const char* path);
int canLoadDylibABS(const char* path);
char** get_loaded_binaries_via_memory(int *count_out);

#endif

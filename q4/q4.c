
// Usage: echo "add 1 2" | ./calc

#include <stdio.h>      /* printf, fgets, fprintf, sscanf */
#include <stdlib.h>     /* exit                           */
#include <string.h>     /* strcpy, strcat                 */
#include <dlfcn.h>      /* dlopen, dlsym, dlclose, dlerror */

#define MAX_OP_LEN 6 // max op name length (5 + null)
#define MAX_OP_LEN 6

#define MAX_LINE_LEN 128 // input line buffer size
#define MAX_LINE_LEN 128

#define MAX_LIB_PATH 32 // buffer for library path
#define MAX_LIB_PATH 32

// function pointer type for operation
typedef int (*operation_func)(int, int);

int main(void)
{
    char line[MAX_LINE_LEN];   // input buffer
    char op[MAX_OP_LEN];       // operation name
    int  num1, num2;           // operands
    char lib_path[MAX_LIB_PATH]; // library path
    void *lib_handle;          // handle for shared library
    operation_func op_func;    // function pointer
    int  result;               // result
    char *dl_error;            // error string

    // Read lines until EOF
    while (fgets(line, MAX_LINE_LEN, stdin) != NULL)
    {
        // Parse: op num1 num2
        if (sscanf(line, "%5s %d %d", op, &num1, &num2) != 3)
        {
            // Skip bad lines
            continue;
        }

        // Build library path: ./lib<op>.so
        strcpy(lib_path, "./lib");
        strcat(lib_path, op);
        strcat(lib_path, ".so");

        // Load the shared library
        lib_handle = dlopen(lib_path, RTLD_LAZY);

        if (lib_handle == NULL)
        {
            // Print error if library can't be loaded
            fprintf(stderr, "Error loading '%s': %s\n", lib_path, dlerror());
            continue;
        }

        // Look up the function in the library
        dlerror();  /* Step 1: clear old error state */

        *(void **)(&op_func) = dlsym(lib_handle, op);  /* Step 2: look up */

        dl_error = dlerror();  /* Step 3: check for errors */
        if (dl_error != NULL)
        {
                fprintf(stderr, "Error finding '%s' in '%s': %s\n",
                    op, lib_path, dl_error);
                dlclose(lib_handle);  // close even if symbol not found
                continue;
        }

        // Call the function
        result = op_func(num1, num2);

        // Print result
        printf("%d\n", result);

        // Unload the library right after use (important for memory limit)
        dlclose(lib_handle);
        lib_handle = NULL;
        op_func    = NULL;
    }

    // Done
    return 0;
}

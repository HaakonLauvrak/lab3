#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include <inttypes.h>

int main(int argc, char *argv[])
{
    if (argc < 2 || argc > 3)
    {
        printf("Usage: vatopa virtual_address [pid]\n");
        return 0;
    }
    uint64 va = atoi(argv[1]);
    int pid = (argc == 3) ? atoi(argv[2]) : getpid();
    uint64 pa = va2pa(va, pid);
    printf("0x%x\n", pa);

    return 0;
}
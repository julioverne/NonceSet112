#ifndef COMMON_H
#define COMMON_H

#include <stdint.h>             // uint*_t

#define LOG(...)
#ifdef __LP64__
#   define ADDR "0x%016llx"
    typedef uint64_t kptr_t;
#else
#   define ADDR "0x%08x"
    typedef uint32_t kptr_t;
#endif

#endif

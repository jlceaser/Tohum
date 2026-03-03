/*
 * tohum_memory.c — Every byte Tohum touches is tracked here.
 */

#include "tohum_memory.h"
#include <stdlib.h>
#include <string.h>

static size_t s_bytes_used = 0;
static size_t s_alloc_count = 0;

void *tohum_alloc(size_t size) {
    if (size == 0) return NULL;

    void *ptr = malloc(size);
    if (ptr) {
        s_bytes_used += size;
        s_alloc_count++;
        memset(ptr, 0, size); /* zero-init always */
    }
    return ptr;
}

void *tohum_realloc(void *ptr, size_t old_size, size_t new_size) {
    if (new_size == 0) {
        tohum_free(ptr, old_size);
        return NULL;
    }

    if (ptr == NULL) {
        return tohum_alloc(new_size);
    }

    void *new_ptr = realloc(ptr, new_size);
    if (new_ptr) {
        s_bytes_used = s_bytes_used - old_size + new_size;
        /* zero-init the new portion */
        if (new_size > old_size) {
            memset((char *)new_ptr + old_size, 0, new_size - old_size);
        }
    }
    return new_ptr;
}

void tohum_free(void *ptr, size_t size) {
    if (ptr == NULL) return;
    s_bytes_used -= size;
    free(ptr);
}

size_t tohum_memory_used(void) {
    return s_bytes_used;
}

size_t tohum_alloc_count(void) {
    return s_alloc_count;
}

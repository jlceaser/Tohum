/*
 * tohum_memory.h — Tohum's memory layer
 *
 * Every allocation in Tohum goes through here.
 * No malloc/free called directly anywhere else.
 * This gives us full control: tracking, debugging, limits.
 */

#ifndef TOHUM_MEMORY_H
#define TOHUM_MEMORY_H

#include <stddef.h>

/* Allocate fresh memory. Returns NULL on failure. */
void *tohum_alloc(size_t size);

/* Resize an existing allocation. old_size must be accurate. */
void *tohum_realloc(void *ptr, size_t old_size, size_t new_size);

/* Free memory. size must match what was allocated. */
void tohum_free(void *ptr, size_t size);

/* How many bytes are currently alive? */
size_t tohum_memory_used(void);

/* How many allocations have been made total? */
size_t tohum_alloc_count(void);

#endif /* TOHUM_MEMORY_H */

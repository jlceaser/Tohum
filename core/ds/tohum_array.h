/*
 * tohum_array.h — Dynamic array (replaces std::vector)
 *
 * Generic growable array. Type-safe through macros.
 * Every resize goes through tohum_memory.
 */

#ifndef TOHUM_ARRAY_H
#define TOHUM_ARRAY_H

#include "../tohum_memory.h"
#include <stddef.h>
#include <string.h>

typedef struct {
    void *data;
    size_t length;      /* number of elements in use */
    size_t capacity;    /* allocated slots */
    size_t elem_size;   /* sizeof one element */
} TohumArray;

/* Initialize an array for elements of given size */
void tohum_array_init(TohumArray *arr, size_t elem_size);

/* Free all memory */
void tohum_array_free(TohumArray *arr);

/* Append an element (copies elem_size bytes from src) */
void tohum_array_push(TohumArray *arr, const void *element);

/* Remove and copy last element into dest. Returns 0 if empty. */
int tohum_array_pop(TohumArray *arr, void *dest);

/* Get pointer to element at index. No bounds check. */
void *tohum_array_get(const TohumArray *arr, size_t index);

/* Set element at index. No bounds check. */
void tohum_array_set(TohumArray *arr, size_t index, const void *element);

/* Ensure capacity for at least n elements */
void tohum_array_reserve(TohumArray *arr, size_t min_capacity);

/* Clear without freeing (length = 0, capacity unchanged) */
void tohum_array_clear(TohumArray *arr);

/* --- Type-safe macros --- */

#define TOHUM_ARRAY_INIT(arr, type) \
    tohum_array_init((arr), sizeof(type))

#define TOHUM_ARRAY_PUSH(arr, value) do { \
    __typeof__(value) _tmp = (value); \
    tohum_array_push((arr), &_tmp); \
} while (0)

#define TOHUM_ARRAY_GET(arr, index, type) \
    (*(type *)tohum_array_get((arr), (index)))

#define TOHUM_ARRAY_SET(arr, index, value) do { \
    __typeof__(value) _tmp = (value); \
    tohum_array_set((arr), (index), &_tmp); \
} while (0)

#define TOHUM_ARRAY_POP(arr, dest) \
    tohum_array_pop((arr), (dest))

#endif /* TOHUM_ARRAY_H */

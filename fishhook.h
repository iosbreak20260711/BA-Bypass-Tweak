#ifndef fishhook_h
#define fishhook_h

#include <stddef.h>
#include <mach-o/dyld.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * A structure representing a particular intended rebinding from a symbol
 * name to its replacement
 */
struct rebinding {
    const char *name;
    void       *replacement;
    void      **replaced;
};

/*
 * For each rebinding in rebindings, rebinds references to external,
 * indirect symbols with the specified name to instead point at
 * replacement for each image in the calling process.
 *
 * Argument rebindings is a pointer to an array of rebinding structures.
 * Argument rebindings_nel is the number of rebinding structures in the
 * array.
 */
int rebind_symbols(struct rebinding rebindings[], size_t rebindings_nel);

/*
 * Rebinds as above, but only in the specified image. The header should
 * point to the mach header of the image to rebind.
 */
int rebind_symbols_image(void *header,
                         intptr_t slide,
                         struct rebinding rebindings[],
                         size_t rebindings_nel);

#ifdef __cplusplus
}
#endif

#endif /* fishhook_h */

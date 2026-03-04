/*
 * mc.c — M language compiler driver
 *
 * Usage: mc <file.m>
 * Reads M source, resolves use directives, compiles, runs.
 * Exit code = return value of main().
 */

#include "parser.h"
#include "codegen.h"
#include "vm.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static char *read_file(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) {
        fprintf(stderr, "mc: cannot open '%s'\n", path);
        return NULL;
    }

    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);

    char *buf = malloc(size + 1);
    if (!buf) {
        fclose(f);
        fprintf(stderr, "mc: out of memory\n");
        return NULL;
    }

    fread(buf, 1, size, f);
    buf[size] = '\0';
    fclose(f);
    return buf;
}

/* ── use directive preprocessor ────────────────────── */

#define MAX_INCLUDES 64

static const char *included_files[MAX_INCLUDES];
static int included_count = 0;

static int already_included(const char *path) {
    for (int i = 0; i < included_count; i++) {
        if (strcmp(included_files[i], path) == 0) return 1;
    }
    return 0;
}

/* Extract directory from a file path */
static void get_dir(const char *path, char *dir, int dir_size) {
    const char *last_sep = NULL;
    for (const char *p = path; *p; p++) {
        if (*p == '/' || *p == '\\') last_sep = p;
    }
    if (last_sep) {
        int len = (int)(last_sep - path + 1);
        if (len >= dir_size) len = dir_size - 1;
        memcpy(dir, path, len);
        dir[len] = '\0';
    } else {
        dir[0] = '\0';
    }
}

/*
 * Resolve use directives in source.
 * Scans for lines like: use "path";
 * Replaces them with the file's content (recursively).
 * Returns newly allocated string. Caller must free.
 */
static char *resolve_uses(const char *source, const char *base_dir) {
    /* Estimate output size */
    size_t out_cap = strlen(source) * 2 + 4096;
    char *out = malloc(out_cap);
    size_t out_len = 0;

    const char *p = source;
    while (*p) {
        /* Check for "use " at start of line (or after whitespace) */
        const char *line_start = p;

        /* Skip whitespace at start of line */
        while (*p == ' ' || *p == '\t') p++;

        if (strncmp(p, "use ", 4) == 0) {
            p += 4;
            /* Skip whitespace */
            while (*p == ' ' || *p == '\t') p++;
            if (*p == '"') {
                p++;
                const char *path_start = p;
                while (*p && *p != '"') p++;
                if (*p == '"') {
                    int path_len = (int)(p - path_start);
                    p++; /* skip closing quote */
                    /* Skip optional semicolon and newline */
                    while (*p == ' ' || *p == '\t') p++;
                    if (*p == ';') p++;
                    if (*p == '\r') p++;
                    if (*p == '\n') p++;

                    /* Build full path */
                    char full_path[512];
                    if (path_len > 0 && (path_start[0] == '/' || path_start[0] == '\\' ||
                        (path_len > 1 && path_start[1] == ':'))) {
                        /* Absolute path */
                        snprintf(full_path, sizeof(full_path), "%.*s", path_len, path_start);
                    } else {
                        /* Relative to base dir */
                        snprintf(full_path, sizeof(full_path), "%s%.*s",
                                 base_dir, path_len, path_start);
                    }

                    if (!already_included(full_path)) {
                        if (included_count < MAX_INCLUDES) {
                            included_files[included_count++] = strdup(full_path);
                        }

                        char *inc_source = read_file(full_path);
                        if (inc_source) {
                            /* Resolve uses in the included file */
                            char inc_dir[512];
                            get_dir(full_path, inc_dir, sizeof(inc_dir));
                            char *resolved = resolve_uses(inc_source, inc_dir);
                            free(inc_source);

                            size_t rlen = strlen(resolved);
                            /* Grow output if needed */
                            while (out_len + rlen + 2 > out_cap) {
                                out_cap *= 2;
                                out = realloc(out, out_cap);
                            }
                            memcpy(out + out_len, resolved, rlen);
                            out_len += rlen;
                            /* Ensure newline after included content */
                            if (rlen > 0 && resolved[rlen-1] != '\n') {
                                out[out_len++] = '\n';
                            }
                            free(resolved);
                        } else {
                            fprintf(stderr, "mc: warning: cannot open '%s'\n", full_path);
                        }
                    }
                    continue;
                }
            }
        }

        /* Not a use directive — copy line as-is */
        p = line_start;
        while (*p && *p != '\n') {
            if (out_len + 2 > out_cap) {
                out_cap *= 2;
                out = realloc(out, out_cap);
            }
            out[out_len++] = *p++;
        }
        if (*p == '\n') {
            out[out_len++] = *p++;
        }
    }

    out[out_len] = '\0';
    return out;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "usage: mc <file.m>\n");
        return 1;
    }

    char *raw_source = read_file(argv[1]);
    if (!raw_source) return 1;

    /* Resolve use directives */
    char base_dir[512];
    get_dir(argv[1], base_dir, sizeof(base_dir));
    char *source = resolve_uses(raw_source, base_dir);
    free(raw_source);

    /* Parse */
    Parser p;
    parser_init(&p, source);
    Program *prog = parser_parse(&p);
    if (parser_had_error(&p)) {
        fprintf(stderr, "mc: parse error: %s\n", parser_error(&p));
        free(source);
        return 1;
    }

    /* Compile */
    Compiler c;
    compiler_init(&c);
    if (compiler_compile(&c, prog) != 0) {
        fprintf(stderr, "mc: compile error: %s\n", compiler_error(&c));
        free(source);
        return 1;
    }

    /* Run */
    VM vm;
    vm_init(&vm, compiler_module(&c));
    vm.prog_argc = argc - 1;
    vm.prog_argv = (const char **)(argv + 1);
    VMResult r = vm_run(&vm, "main");

    /* Print captured output */
    if (vm.output_len > 0) {
        fwrite(vm.output, 1, vm.output_len, stdout);
    }

    if (r == VM_ERROR) {
        fprintf(stderr, "mc: runtime error: %s\n", vm_error(&vm));
        free(source);
        return 1;
    }

    Val result = vm_result(&vm);
    int exit_code = 0;
    if (result.type == VAL_INT) {
        exit_code = (int)result.i;
    }

    free(source);
    return exit_code;
}

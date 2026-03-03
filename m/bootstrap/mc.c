/*
 * mc.c — M language compiler driver
 *
 * Usage: mc <file.m>
 * Reads M source, compiles, runs.
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

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "usage: mc <file.m>\n");
        return 1;
    }

    char *source = read_file(argv[1]);
    if (!source) return 1;

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

/*
 * test_lexer.c — Verify the M lexer works.
 * Bootstrap test: will be replaced by M-language tests.
 */

#include "lexer.h"
#include <stdio.h>
#include <string.h>

static int tests_run = 0;
static int tests_passed = 0;

static void check(int condition, const char *name) {
    tests_run++;
    if (condition) {
        tests_passed++;
    } else {
        printf("  FAIL: %s\n", name);
    }
}

static void test_basic_tokens(void) {
    Lexer lex;
    lexer_init(&lex, "fn main() -> i32 { return 0; }");

    Token t;
    t = lexer_next(&lex); check(t.type == TOK_FN, "fn keyword");
    t = lexer_next(&lex); check(t.type == TOK_IDENT, "main ident");
    check(t.length == 4 && memcmp(t.start, "main", 4) == 0, "main value");
    t = lexer_next(&lex); check(t.type == TOK_LPAREN, "(");
    t = lexer_next(&lex); check(t.type == TOK_RPAREN, ")");
    t = lexer_next(&lex); check(t.type == TOK_ARROW, "->");
    t = lexer_next(&lex); check(t.type == TOK_I32, "i32 type");
    t = lexer_next(&lex); check(t.type == TOK_LBRACE, "{");
    t = lexer_next(&lex); check(t.type == TOK_RETURN, "return");
    t = lexer_next(&lex); check(t.type == TOK_INT_LIT, "0 literal");
    check(t.int_val == 0, "0 value");
    t = lexer_next(&lex); check(t.type == TOK_SEMICOLON, ";");
    t = lexer_next(&lex); check(t.type == TOK_RBRACE, "}");
    t = lexer_next(&lex); check(t.type == TOK_EOF, "EOF");
}

static void test_numbers(void) {
    Lexer lex;
    lexer_init(&lex, "42 3.14 0xFF");

    Token t;
    t = lexer_next(&lex); check(t.type == TOK_INT_LIT, "42 is int");
    check(t.int_val == 42, "42 value");

    t = lexer_next(&lex); check(t.type == TOK_FLOAT_LIT, "3.14 is float");
    check(t.float_val > 3.13 && t.float_val < 3.15, "3.14 value");

    t = lexer_next(&lex); check(t.type == TOK_INT_LIT, "0xFF is int");
    check(t.int_val == 255, "0xFF = 255");
}

static void test_strings(void) {
    Lexer lex;
    lexer_init(&lex, "\"hello\" \"world\"");

    Token t;
    t = lexer_next(&lex); check(t.type == TOK_STRING_LIT, "string 1");
    check(t.length == 5 && memcmp(t.start, "hello", 5) == 0, "hello value");

    t = lexer_next(&lex); check(t.type == TOK_STRING_LIT, "string 2");
    check(t.length == 5 && memcmp(t.start, "world", 5) == 0, "world value");
}

static void test_operators(void) {
    Lexer lex;
    lexer_init(&lex, "== != <= >= && || + - * / !");

    Token t;
    t = lexer_next(&lex); check(t.type == TOK_EQ, "==");
    t = lexer_next(&lex); check(t.type == TOK_NEQ, "!=");
    t = lexer_next(&lex); check(t.type == TOK_LTE, "<=");
    t = lexer_next(&lex); check(t.type == TOK_GTE, ">=");
    t = lexer_next(&lex); check(t.type == TOK_AND, "&&");
    t = lexer_next(&lex); check(t.type == TOK_OR, "||");
    t = lexer_next(&lex); check(t.type == TOK_PLUS, "+");
    t = lexer_next(&lex); check(t.type == TOK_MINUS, "-");
    t = lexer_next(&lex); check(t.type == TOK_STAR, "*");
    t = lexer_next(&lex); check(t.type == TOK_SLASH, "/");
    t = lexer_next(&lex); check(t.type == TOK_NOT, "!");
}

static void test_full_program(void) {
    const char *src =
        "struct Point {\n"
        "    x: f64,\n"
        "    y: f64,\n"
        "}\n"
        "\n"
        "fn add(a: i32, b: i32) -> i32 {\n"
        "    let result: i32 = a + b;\n"
        "    return result;\n"
        "}\n";

    Lexer lex;
    lexer_init(&lex, src);

    /* Just count tokens — verify no errors */
    int count = 0;
    Token t;
    do {
        t = lexer_next(&lex);
        check(t.type != TOK_ERROR, "no error in full program");
        count++;
    } while (t.type != TOK_EOF);

    check(count > 20, "enough tokens in full program");
}

static void test_comments(void) {
    Lexer lex;
    lexer_init(&lex, "42 // this is a comment\n 7 /* block */ 3");

    Token t;
    t = lexer_next(&lex); check(t.type == TOK_INT_LIT && t.int_val == 42, "before comment");
    t = lexer_next(&lex); check(t.type == TOK_INT_LIT && t.int_val == 7, "after line comment");
    t = lexer_next(&lex); check(t.type == TOK_INT_LIT && t.int_val == 3, "after block comment");
}

int main(void) {
    printf("M lexer tests\n");

    test_basic_tokens();
    test_numbers();
    test_strings();
    test_operators();
    test_full_program();
    test_comments();

    printf("\n%d/%d tests passed\n", tests_passed, tests_run);
    return tests_passed == tests_run ? 0 : 1;
}

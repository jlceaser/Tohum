/*
 * lexer.c — M language tokenizer
 *
 * Reads source text, produces tokens.
 * No dynamic allocation. Tokens point into the source string.
 */

#include "lexer.h"
#include <string.h>
#include <ctype.h>

void lexer_init(Lexer *lex, const char *source) {
    lex->source = source;
    lex->current = source;
    lex->line = 1;
    lex->col = 1;
}

static char peek(Lexer *lex) {
    return *lex->current;
}

static char peek_next(Lexer *lex) {
    if (*lex->current == '\0') return '\0';
    return lex->current[1];
}

static char advance(Lexer *lex) {
    char c = *lex->current++;
    if (c == '\n') {
        lex->line++;
        lex->col = 1;
    } else {
        lex->col++;
    }
    return c;
}

static int match(Lexer *lex, char expected) {
    if (*lex->current != expected) return 0;
    advance(lex);
    return 1;
}

static Token make_token(Lexer *lex, TokenType type, const char *start, int line, int col) {
    Token tok;
    tok.type = type;
    tok.start = start;
    tok.length = (int)(lex->current - start);
    tok.line = line;
    tok.col = col;
    tok.int_val = 0;
    return tok;
}

static Token error_token(Lexer *lex, const char *msg) {
    Token tok;
    tok.type = TOK_ERROR;
    tok.start = msg;
    tok.length = (int)strlen(msg);
    tok.line = lex->line;
    tok.col = lex->col;
    tok.int_val = 0;
    return tok;
}

static void skip_whitespace(Lexer *lex) {
    for (;;) {
        char c = peek(lex);
        switch (c) {
        case ' ':
        case '\t':
        case '\r':
        case '\n':
            advance(lex);
            break;
        case '/':
            if (peek_next(lex) == '/') {
                /* line comment */
                while (peek(lex) != '\n' && peek(lex) != '\0') advance(lex);
                break;
            }
            if (peek_next(lex) == '*') {
                /* block comment */
                advance(lex); advance(lex);
                while (!(peek(lex) == '*' && peek_next(lex) == '/')) {
                    if (peek(lex) == '\0') return;
                    advance(lex);
                }
                advance(lex); advance(lex);
                break;
            }
            return;
        default:
            return;
        }
    }
}

/* Check if identifier matches a keyword */
static TokenType check_keyword(const char *start, int length) {
    /* Keywords sorted by length for quick rejection */
    struct { const char *word; int len; TokenType type; } keywords[] = {
        {"fn",     2, TOK_FN},
        {"if",     2, TOK_IF},
        {"u8",     2, TOK_U8},
        {"i8",     2, TOK_I8},
        {"let",    3, TOK_LET},
        {"var",    3, TOK_VAR},
        {"ptr",    3, TOK_PTR},
        {"u16",    3, TOK_U16},
        {"u32",    3, TOK_U32},
        {"u64",    3, TOK_U64},
        {"i16",    3, TOK_I16},
        {"i32",    3, TOK_I32},
        {"i64",    3, TOK_I64},
        {"f64",    3, TOK_F64},
        {"else",   4, TOK_ELSE},
        {"bool",   4, TOK_BOOL},
        {"true",   4, TOK_TRUE},
        {"void",   4, TOK_VOID},
        {"free",   4, TOK_FREE},
        {"false",  5, TOK_FALSE},
        {"while",  5, TOK_WHILE},
        {"alloc",  5, TOK_ALLOC},
        {"struct", 6, TOK_STRUCT},
        {"return", 6, TOK_RETURN},
        {NULL,     0, TOK_ERROR},
    };

    for (int i = 0; keywords[i].word != NULL; i++) {
        if (keywords[i].len == length &&
            memcmp(start, keywords[i].word, length) == 0) {
            return keywords[i].type;
        }
    }

    return TOK_IDENT;
}

static Token scan_identifier(Lexer *lex) {
    const char *start = lex->current - 1; /* we already consumed first char */
    int line = lex->line, col = lex->col - 1;

    while (isalnum(peek(lex)) || peek(lex) == '_') {
        advance(lex);
    }

    int length = (int)(lex->current - start);
    TokenType type = check_keyword(start, length);

    Token tok = make_token(lex, type, start, line, col);
    return tok;
}

static Token scan_number(Lexer *lex) {
    const char *start = lex->current - 1;
    int line = lex->line, col = lex->col - 1;
    int is_float = 0;

    /* Hex literal */
    if (start[0] == '0' && (peek(lex) == 'x' || peek(lex) == 'X')) {
        advance(lex);
        while (isxdigit(peek(lex))) advance(lex);
        Token tok = make_token(lex, TOK_INT_LIT, start, line, col);
        /* parse hex */
        tok.int_val = 0;
        for (const char *p = start + 2; p < lex->current; p++) {
            tok.int_val *= 16;
            if (*p >= '0' && *p <= '9') tok.int_val += *p - '0';
            else if (*p >= 'a' && *p <= 'f') tok.int_val += *p - 'a' + 10;
            else if (*p >= 'A' && *p <= 'F') tok.int_val += *p - 'A' + 10;
        }
        return tok;
    }

    while (isdigit(peek(lex))) advance(lex);

    if (peek(lex) == '.' && isdigit(peek_next(lex))) {
        is_float = 1;
        advance(lex); /* consume '.' */
        while (isdigit(peek(lex))) advance(lex);
    }

    Token tok = make_token(lex, is_float ? TOK_FLOAT_LIT : TOK_INT_LIT, start, line, col);

    if (is_float) {
        /* parse float manually */
        double val = 0.0;
        const char *p = start;
        while (p < lex->current && *p != '.') {
            val = val * 10.0 + (*p - '0');
            p++;
        }
        if (p < lex->current) p++; /* skip dot */
        double frac = 0.1;
        while (p < lex->current) {
            val += (*p - '0') * frac;
            frac *= 0.1;
            p++;
        }
        tok.float_val = val;
    } else {
        tok.int_val = 0;
        for (const char *p = start; p < lex->current; p++) {
            tok.int_val = tok.int_val * 10 + (*p - '0');
        }
    }

    return tok;
}

static Token scan_string(Lexer *lex) {
    const char *start = lex->current; /* after opening quote */
    int line = lex->line, col = lex->col;

    while (peek(lex) != '"' && peek(lex) != '\0') {
        if (peek(lex) == '\\') advance(lex); /* skip escape */
        advance(lex);
    }

    if (peek(lex) == '\0') {
        return error_token(lex, "unterminated string");
    }

    Token tok;
    tok.type = TOK_STRING_LIT;
    tok.start = start;
    tok.length = (int)(lex->current - start);
    tok.line = line;
    tok.col = col;
    tok.int_val = 0;

    advance(lex); /* consume closing quote */
    return tok;
}

Token lexer_next(Lexer *lex) {
    skip_whitespace(lex);

    if (peek(lex) == '\0') {
        Token tok;
        tok.type = TOK_EOF;
        tok.start = lex->current;
        tok.length = 0;
        tok.line = lex->line;
        tok.col = lex->col;
        tok.int_val = 0;
        return tok;
    }

    int line = lex->line, col = lex->col;
    char c = advance(lex);

    /* Identifiers and keywords */
    if (isalpha(c) || c == '_') return scan_identifier(lex);

    /* Numbers */
    if (isdigit(c)) return scan_number(lex);

    /* Strings */
    if (c == '"') return scan_string(lex);

    /* Operators and punctuation */
    switch (c) {
    case '(': return make_token(lex, TOK_LPAREN, lex->current - 1, line, col);
    case ')': return make_token(lex, TOK_RPAREN, lex->current - 1, line, col);
    case '{': return make_token(lex, TOK_LBRACE, lex->current - 1, line, col);
    case '}': return make_token(lex, TOK_RBRACE, lex->current - 1, line, col);
    case '[': return make_token(lex, TOK_LBRACKET, lex->current - 1, line, col);
    case ']': return make_token(lex, TOK_RBRACKET, lex->current - 1, line, col);
    case ',': return make_token(lex, TOK_COMMA, lex->current - 1, line, col);
    case ':': return make_token(lex, TOK_COLON, lex->current - 1, line, col);
    case ';': return make_token(lex, TOK_SEMICOLON, lex->current - 1, line, col);
    case '.': return make_token(lex, TOK_DOT, lex->current - 1, line, col);
    case '&':
        if (match(lex, '&')) return make_token(lex, TOK_AND, lex->current - 2, line, col);
        return make_token(lex, TOK_AMPERSAND, lex->current - 1, line, col);
    case '+': return make_token(lex, TOK_PLUS, lex->current - 1, line, col);
    case '*': return make_token(lex, TOK_STAR, lex->current - 1, line, col);
    case '%': return make_token(lex, TOK_PERCENT, lex->current - 1, line, col);
    case '/': return make_token(lex, TOK_SLASH, lex->current - 1, line, col);
    case '-':
        if (match(lex, '>')) return make_token(lex, TOK_ARROW, lex->current - 2, line, col);
        return make_token(lex, TOK_MINUS, lex->current - 1, line, col);
    case '=':
        if (match(lex, '=')) return make_token(lex, TOK_EQ, lex->current - 2, line, col);
        return make_token(lex, TOK_ASSIGN, lex->current - 1, line, col);
    case '!':
        if (match(lex, '=')) return make_token(lex, TOK_NEQ, lex->current - 2, line, col);
        return make_token(lex, TOK_NOT, lex->current - 1, line, col);
    case '<':
        if (match(lex, '=')) return make_token(lex, TOK_LTE, lex->current - 2, line, col);
        return make_token(lex, TOK_LT, lex->current - 1, line, col);
    case '>':
        if (match(lex, '=')) return make_token(lex, TOK_GTE, lex->current - 2, line, col);
        return make_token(lex, TOK_GT, lex->current - 1, line, col);
    case '|':
        if (match(lex, '|')) return make_token(lex, TOK_OR, lex->current - 2, line, col);
        return error_token(lex, "unexpected '|' (did you mean '||'?)");
    }

    return error_token(lex, "unexpected character");
}

Token lexer_peek(Lexer *lex) {
    /* Save state */
    const char *saved_current = lex->current;
    int saved_line = lex->line;
    int saved_col = lex->col;

    Token tok = lexer_next(lex);

    /* Restore state */
    lex->current = saved_current;
    lex->line = saved_line;
    lex->col = saved_col;

    return tok;
}

const char *token_type_name(TokenType type) {
    switch (type) {
    case TOK_INT_LIT: return "integer";
    case TOK_FLOAT_LIT: return "float";
    case TOK_STRING_LIT: return "string";
    case TOK_TRUE: return "true";
    case TOK_FALSE: return "false";
    case TOK_FN: return "fn";
    case TOK_LET: return "let";
    case TOK_VAR: return "var";
    case TOK_STRUCT: return "struct";
    case TOK_IF: return "if";
    case TOK_ELSE: return "else";
    case TOK_WHILE: return "while";
    case TOK_RETURN: return "return";
    case TOK_ALLOC: return "alloc";
    case TOK_FREE: return "free";
    case TOK_PTR: return "ptr";
    case TOK_IDENT: return "identifier";
    case TOK_U8: return "u8";
    case TOK_U16: return "u16";
    case TOK_U32: return "u32";
    case TOK_U64: return "u64";
    case TOK_I8: return "i8";
    case TOK_I16: return "i16";
    case TOK_I32: return "i32";
    case TOK_I64: return "i64";
    case TOK_F64: return "f64";
    case TOK_BOOL: return "bool";
    case TOK_VOID: return "void";
    case TOK_PLUS: return "+";
    case TOK_MINUS: return "-";
    case TOK_STAR: return "*";
    case TOK_SLASH: return "/";
    case TOK_PERCENT: return "%";
    case TOK_EQ: return "==";
    case TOK_NEQ: return "!=";
    case TOK_LT: return "<";
    case TOK_GT: return ">";
    case TOK_LTE: return "<=";
    case TOK_GTE: return ">=";
    case TOK_AND: return "&&";
    case TOK_OR: return "||";
    case TOK_NOT: return "!";
    case TOK_ASSIGN: return "=";
    case TOK_ARROW: return "->";
    case TOK_LPAREN: return "(";
    case TOK_RPAREN: return ")";
    case TOK_LBRACE: return "{";
    case TOK_RBRACE: return "}";
    case TOK_LBRACKET: return "[";
    case TOK_RBRACKET: return "]";
    case TOK_COMMA: return ",";
    case TOK_COLON: return ":";
    case TOK_SEMICOLON: return ";";
    case TOK_DOT: return ".";
    case TOK_AMPERSAND: return "&";
    case TOK_EOF: return "EOF";
    case TOK_ERROR: return "error";
    }
    return "unknown";
}

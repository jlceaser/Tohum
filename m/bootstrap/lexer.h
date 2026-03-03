/*
 * lexer.h — M language tokenizer
 *
 * Bootstrap version: written in C so M can be born.
 * This file will be deleted once M compiles itself.
 */

#ifndef M_LEXER_H
#define M_LEXER_H

typedef enum {
    /* Literals */
    TOK_INT_LIT,       /* 42, 0xFF */
    TOK_FLOAT_LIT,     /* 3.14 */
    TOK_STRING_LIT,    /* "hello" */
    TOK_TRUE,          /* true */
    TOK_FALSE,         /* false */

    /* Keywords */
    TOK_FN,            /* fn */
    TOK_LET,           /* let */
    TOK_VAR,           /* var */
    TOK_STRUCT,        /* struct */
    TOK_IF,            /* if */
    TOK_ELSE,          /* else */
    TOK_WHILE,         /* while */
    TOK_RETURN,        /* return */
    TOK_ALLOC,         /* alloc */
    TOK_FREE,          /* free */
    TOK_PTR,           /* ptr */

    /* Identifier */
    TOK_IDENT,         /* any name */

    /* Types */
    TOK_U8, TOK_U16, TOK_U32, TOK_U64,
    TOK_I8, TOK_I16, TOK_I32, TOK_I64,
    TOK_F64,
    TOK_BOOL,
    TOK_VOID,

    /* Operators */
    TOK_PLUS,          /* + */
    TOK_MINUS,         /* - */
    TOK_STAR,          /* * */
    TOK_SLASH,         /* / */
    TOK_PERCENT,       /* % */
    TOK_EQ,            /* == */
    TOK_NEQ,           /* != */
    TOK_LT,            /* < */
    TOK_GT,            /* > */
    TOK_LTE,           /* <= */
    TOK_GTE,           /* >= */
    TOK_AND,           /* && */
    TOK_OR,            /* || */
    TOK_NOT,           /* ! */
    TOK_ASSIGN,        /* = */
    TOK_ARROW,         /* -> */

    /* Punctuation */
    TOK_LPAREN,        /* ( */
    TOK_RPAREN,        /* ) */
    TOK_LBRACE,        /* { */
    TOK_RBRACE,        /* } */
    TOK_LBRACKET,      /* [ */
    TOK_RBRACKET,      /* ] */
    TOK_COMMA,         /* , */
    TOK_COLON,         /* : */
    TOK_SEMICOLON,     /* ; */
    TOK_DOT,           /* . */
    TOK_AMPERSAND,     /* & (address-of) */

    /* Special */
    TOK_EOF,
    TOK_ERROR,
} TokenType;

typedef struct {
    TokenType type;
    const char *start;  /* pointer into source */
    int length;
    int line;
    int col;

    /* for numeric literals */
    union {
        long long int_val;
        double float_val;
    };
} Token;

typedef struct {
    const char *source;
    const char *current;
    int line;
    int col;
} Lexer;

/* Initialize lexer with source code */
void lexer_init(Lexer *lex, const char *source);

/* Get next token */
Token lexer_next(Lexer *lex);

/* Peek at next token without consuming */
Token lexer_peek(Lexer *lex);

/* Token type name for error messages */
const char *token_type_name(TokenType type);

#endif /* M_LEXER_H */

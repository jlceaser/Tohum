// ════════════════════════════════════════════════
// Source: m/bootstrap/bytecode.c
// ════════════════════════════════════════════════

// Auto-translated from C by Machine
// Phase 2: M reads C, writes M

fn chunk_init(c: string) -> i32 {
    memset(c, 0, 0 /* sizeof(Chunk) */);
}

fn chunk_free(c: string) -> i32 {
    if c_code {
        tohum_free(c_code, c_code_cap);
    }
    if c_ints {
        tohum_free(c_ints, (c_int_cap * 0 /* sizeof(int64_t) */));
    }
    if c_floats {
        tohum_free(c_floats, (c_float_cap * 0 /* sizeof(double) */));
    }
    if c_strings {
        tohum_free(c_strings, (c_string_cap * 0 /* sizeof(c -> strings [ 0 ]) */));
    }
    if c_lines {
        tohum_free(c_lines, (c_code_cap * 0 /* sizeof(int) */));
    }
    memset(c, 0, 0 /* sizeof(Chunk) */);
}

fn chunk_grow(c: string) -> i32 {
    var old_cap: i32 = c_code_cap;
    var new_cap: i32 = 0;
    if (old_cap < 8) {
        new_cap = 8;
    } else {
        new_cap = (old_cap * 2);
    }
    c_code = tohum_realloc(c_code, old_cap, new_cap);
    c_lines = tohum_realloc(c_lines, (old_cap * 0 /* sizeof(int) */), (new_cap * 0 /* sizeof(int) */));
    c_code_cap = new_cap;
}

fn chunk_write(c: string, byte: i32, line: i32) -> i32 {
    if (c_code_len >= c_code_cap) {
        chunk_grow(c);
    }
    array_get(c_code, c_code_len) = byte;
    array_get(c_lines, c_code_len) = line;
    c_code_len = c_code_len + 1;
}

fn chunk_write_u16(c: string, val: i32, line: i32) -> i32 {
    chunk_write(c, (val >> 8), line);
    chunk_write(c, (val & 0xFF), line);
}

fn chunk_write_i16(c: string, val: i32, line: i32) -> i32 {
    chunk_write_u16(c, val, line);
}

fn chunk_patch_u16(c: string, offset: i32, val: i32) -> i32 {
    array_get(c_code, offset) = (val >> 8);
    array_get(c_code, (offset + 1)) = (val & 0xFF);
}

fn chunk_patch_i16(c: string, offset: i32, val: i32) -> i32 {
    chunk_patch_u16(c, offset, val);
}

fn chunk_add_int(c: string, val: i32) -> i32 {
    if (c_int_count >= c_int_cap) {
        var old: i32 = c_int_cap;
        if (old < 8) {
            c_int_cap = 8;
        } else {
            c_int_cap = (old * 2);
        }
        c_ints = tohum_realloc(c_ints, (old * 0 /* sizeof(int64_t) */), (c_int_cap * 0 /* sizeof(int64_t) */));
    }
    array_get(c_ints, c_int_count) = val;
    return c_int_count = c_int_count + 1;
}

fn chunk_add_float(c: string, val: i32) -> i32 {
    if (c_float_count >= c_float_cap) {
        var old: i32 = c_float_cap;
        if (old < 8) {
            c_float_cap = 8;
        } else {
            c_float_cap = (old * 2);
        }
        c_floats = tohum_realloc(c_floats, (old * 0 /* sizeof(double) */), (c_float_cap * 0 /* sizeof(double) */));
    }
    array_get(c_floats, c_float_count) = val;
    return c_float_count = c_float_count + 1;
}

fn chunk_add_string(c: string, str: string, len: i32) -> i32 {
    var i: i32 = 0;
    while (i < c_string_count) {
        if ((array_get(c_strings, i)_len == len) && (memcmp(array_get(c_strings, i)_str, str, len) == 0)) {
            return i;
        }
        i = i + 1;
    }
    if (c_string_count >= c_string_cap) {
        var old: i32 = c_string_cap;
        if (old < 8) {
            c_string_cap = 8;
        } else {
            c_string_cap = (old * 2);
        }
        c_strings = tohum_realloc(c_strings, (old * 0 /* sizeof(c -> strings [ 0 ]) */), (c_string_cap * 0 /* sizeof(c -> strings [ 0 ]) */));
    }
    array_get(c_strings, c_string_count)_str = str;
    array_get(c_strings, c_string_count)_len = len;
    return c_string_count = c_string_count + 1;
}

fn module_init(m: string) -> i32 {
    memset(m, 0, 0 /* sizeof(Module) */);
}

fn module_free(m: string) -> i32 {
    var i: i32 = 0;
    while (i < m_func_count) {
        chunk_free(/* &array_get(m_functions, i)_chunk */);
        i = i + 1;
    }
    if m_functions {
        tohum_free(m_functions, (m_func_cap * 0 /* sizeof(Function) */));
    }
    if m_names {
        tohum_free(m_names, (m_name_cap * 0 /* sizeof(m -> names [ 0 ]) */));
    }
    if m_globals {
        tohum_free(m_globals, (m_global_cap * 0 /* sizeof(Val) */));
    }
    memset(m, 0, 0 /* sizeof(Module) */);
}

fn module_add_function(m: string, fn: i32) -> i32 {
    if (m_func_count >= m_func_cap) {
        var old: i32 = m_func_cap;
        if (old < 8) {
            m_func_cap = 8;
        } else {
            m_func_cap = (old * 2);
        }
        m_functions = tohum_realloc(m_functions, (old * 0 /* sizeof(Function) */), (m_func_cap * 0 /* sizeof(Function) */));
    }
    array_get(m_functions, m_func_count) = fn;
    return m_func_count = m_func_count + 1;
}

fn module_add_name(m: string, name: string, len: i32) -> i32 {
    var idx: i32 = module_find_name(m, name, len);
    if (idx >= 0) {
        return idx;
    }
    if (m_name_count >= m_name_cap) {
        var old: i32 = m_name_cap;
        if (old < 8) {
            m_name_cap = 8;
        } else {
            m_name_cap = (old * 2);
        }
        m_names = tohum_realloc(m_names, (old * 0 /* sizeof(m -> names [ 0 ]) */), (m_name_cap * 0 /* sizeof(m -> names [ 0 ]) */));
    }
    array_get(m_names, m_name_count)_name = name;
    array_get(m_names, m_name_count)_len = len;
    return m_name_count = m_name_count + 1;
}

fn module_find_name(m: string, name: string, len: i32) -> i32 {
    var i: i32 = 0;
    while (i < m_name_count) {
        if ((array_get(m_names, i)_len == len) && (memcmp(array_get(m_names, i)_name, name, len) == 0)) {
            return i;
        }
        i = i + 1;
    }
    return (0 - 1);
}


// ════════════════════════════════════════════════
// Source: m/bootstrap/lexer.c
// ════════════════════════════════════════════════

// Auto-translated from C by Machine
// Phase 2: M reads C, writes M

fn lexer_init(lex: string, source: string) -> i32 {
    lex_source = source;
    lex_current = source;
    lex_line = 1;
    lex_col = 1;
}

fn peek(lex: string) -> i32 {
    return /* *lex_current */;
}

fn peek_next(lex: string) -> i32 {
    if (/* *lex_current */ == 0 /* '\0' */) {
        return 0 /* '\0' */;
    }
    return array_get(lex_current, 1);
}

fn advance(lex: string) -> i32 {
    var c: i32 = /* *lex_current = lex_current + 1 */;
    if (c == 10 /* '\n' */) {
        lex_line = lex_line + 1;
        lex_col = 1;
    } else {
        lex_col = lex_col + 1;
    }
    return c;
}

fn match(lex: string, expected: i32) -> i32 {
    if (/* *lex_current */ != expected) {
        return 0;
    }
    advance(lex);
    return 1;
}

fn make_token(lex: string, type: i32, start: string, line: i32, col: i32) -> i32 {
    var tok: i32 = 0;
    tok_type = type;
    tok_start = start;
    tok_length = (lex_current - start);
    tok_line = line;
    tok_col = col;
    tok_int_val = 0;
    return tok;
}

fn error_token(lex: string, msg: string) -> i32 {
    var tok: i32 = 0;
    tok_type = TOK_ERROR;
    tok_start = msg;
    tok_length = strlen(msg);
    tok_line = lex_line;
    tok_col = lex_col;
    tok_int_val = 0;
    return tok;
}

fn skip_whitespace(lex: string) -> i32 {
    while true {
        var c: i32 = peek(lex);
        // switch (c) {
        // case 32 /* ' ' */:
        // case 9 /* '\t' */:
        // case 13 /* '\r' */:
        // case 10 /* '\n' */:
            advance(lex);
            // break;
        // case 47 /* '/' */:
            if (peek_next(lex) == 47 /* '/' */) {
                while ((peek(lex) != 10 /* '\n' */) && (peek(lex) != 0 /* '\0' */)) {
                    advance(lex);
                }
                // break;
            }
            if (peek_next(lex) == /* *) */) {
                advance(lex);
                advance(lex);
                while !(peek(lex) == /* *&& */) {
                    (peek_next(lex) == 47 /* '/' */);
                }
                );
                );
                if (peek(lex) == 0 /* '\0' */) {
                    return 0;
                }
                advance(lex);
                advance(lex);
                advance(lex);
                // break;
            }
            return 0;
        // default:
            return 0;
        // }
    }
}

fn check_keyword(start: string, length: i32) -> i32 {
    struct;
    var word: string = "";
    var len: i32 = 0;
    var type: i32 = 0;
    array_get(keywords, ] = {);
    "fn";
    ,;
    2;
    ,;
    TOK_FN;
    ,;
    if , {
        2;
    }
    ,;
    TOK_IF;
    ,;
    "u8";
    ,;
    2;
    ,;
    TOK_U8;
    ,;
    "i8";
    ,;
    2;
    ,;
    TOK_I8;
    ,;
    "let";
    ,;
    3;
    ,;
    TOK_LET;
    ,;
    "var";
    ,;
    3;
    ,;
    TOK_VAR;
    ,;
    "ptr";
    ,;
    3;
    ,;
    TOK_PTR;
    ,;
    "u16";
    ,;
    3;
    ,;
    TOK_U16;
    ,;
    "u32";
    ,;
    3;
    ,;
    TOK_U32;
    ,;
    "u64";
    ,;
    3;
    ,;
    TOK_U64;
    ,;
    "i16";
    ,;
    3;
    ,;
    TOK_I16;
    ,;
    "i32";
    ,;
    3;
    ,;
    TOK_I32;
    ,;
    "i64";
    ,;
    3;
    ,;
    TOK_I64;
    ,;
    "f64";
    ,;
    3;
    ,;
    TOK_F64;
    ,;
    "else";
    ,;
    4;
    ,;
    TOK_ELSE;
    ,;
    var ,: bool = false;
    4;
    ,;
    TOK_BOOL;
    ,;
    "true";
    ,;
    4;
    ,;
    TOK_TRUE;
    ,;
    var ,: i32 = 0;
    4;
    ,;
    TOK_VOID;
    ,;
    "free";
    ,;
    4;
    ,;
    TOK_FREE;
    ,;
    "false";
    ,;
    5;
    ,;
    TOK_FALSE;
    ,;
    while , {
        5;
    }
    ,;
    TOK_WHILE;
    ,;
    "alloc";
    ,;
    5;
    ,;
    TOK_ALLOC;
    ,;
    "struct";
    ,;
    6;
    ,;
    TOK_STRUCT;
    ,;
    return ,;
    6;
    ,;
    TOK_RETURN;
    ,;
    var ,: i32 = 0;
    0;
    ,;
    TOK_ERROR;
    ,;
}

fn scan_identifier(lex: string) -> i32 {
    var start: string = (lex_current - 1);
    var line: i32 = lex_line;
    while (isalnum(peek(lex)) || (peek(lex) == 95 /* '_' */)) {
        advance(lex);
    }
    var length: i32 = (lex_current - start);
    var type: i32 = check_keyword(start, length);
    var tok: i32 = make_token(lex, type, start, line, col);
    return tok;
}

fn scan_number(lex: string) -> i32 {
    var start: string = (lex_current - 1);
    var line: i32 = lex_line;
    var is_float: i32 = 0;
    if ((array_get(start, 0) == 48 /* '0' */) && ((peek(lex) == 120 /* 'x' */) || (peek(lex) == 88 /* 'X' */))) {
        advance(lex);
        while isxdigit(peek(lex)) {
            advance(lex);
        }
        var tok: i32 = make_token(lex, TOK_INT_LIT, start, line, col);
        tok_int_val = 0;
        var p: string = (start + 2);
        while (p < lex_current) {
            tok_int_val = tok_int_val * 16;
            if ((/* *p */ >= 48 /* '0' */) && (/* *p */ <= 57 /* '9' */)) {
                tok_int_val = tok_int_val + (/* *p */ - 48 /* '0' */);
            } else             if ((/* *p */ >= 97 /* 'a' */) && (/* *p */ <= 102 /* 'f' */)) {
                tok_int_val = tok_int_val + ((/* *p */ - 97 /* 'a' */) + 10);
            } else             if ((/* *p */ >= 65 /* 'A' */) && (/* *p */ <= 70 /* 'F' */)) {
                tok_int_val = tok_int_val + ((/* *p */ - 65 /* 'A' */) + 10);
            }
            p = p + 1;
        }
        return tok;
    }
    while isdigit(peek(lex)) {
        advance(lex);
    }
    if ((peek(lex) == 46 /* '.' */) && isdigit(peek_next(lex))) {
        is_float = 1;
        advance(lex);
        while isdigit(peek(lex)) {
            advance(lex);
        }
    }
    var tok: i32 = make_token(lex, /* is_float ? TOK_FLOAT_LIT : TOK_INT_LIT */, start, line, col);
    if is_float {
        var val: i32 = 0.0;
        var p: string = start;
        while ((p < lex_current) && (/* *p */ != 46 /* '.' */)) {
            val = ((val * 10.0) + (/* *p */ - 48 /* '0' */));
            p = p + 1;
        }
        if (p < lex_current) {
            p = p + 1;
        }
        var frac: i32 = 0.1;
        while (p < lex_current) {
            val = val + ((/* *p */ - 48 /* '0' */) * frac);
            frac = frac * 0.1;
            p = p + 1;
        }
        tok_float_val = val;
    } else {
        tok_int_val = 0;
        var p: string = start;
        while (p < lex_current) {
            tok_int_val = ((tok_int_val * 10) + (/* *p */ - 48 /* '0' */));
            p = p + 1;
        }
    }
    return tok;
}

fn scan_string(lex: string) -> i32 {
    var start: string = lex_current;
    var line: i32 = lex_line;
    while ((peek(lex) != 34 /* '"' */) && (peek(lex) != 0 /* '\0' */)) {
        if (peek(lex) == 92 /* '\\' */) {
            advance(lex);
        }
        advance(lex);
    }
    if (peek(lex) == 0 /* '\0' */) {
        return error_token(lex, "unterminated string");
    }
    var tok: i32 = 0;
    tok_type = TOK_STRING_LIT;
    tok_start = start;
    tok_length = (lex_current - start);
    tok_line = line;
    tok_col = col;
    tok_int_val = 0;
    advance(lex);
    return tok;
}

fn lexer_next(lex: string) -> i32 {
    skip_whitespace(lex);
    if (peek(lex) == 0 /* '\0' */) {
        var tok: i32 = 0;
        tok_type = TOK_EOF;
        tok_start = lex_current;
        tok_length = 0;
        tok_line = lex_line;
        tok_col = lex_col;
        tok_int_val = 0;
        return tok;
    }
    var line: i32 = lex_line;
    var c: i32 = advance(lex);
    if (isalpha(c) || (c == 95 /* '_' */)) {
        return scan_identifier(lex);
    }
    if isdigit(c) {
        return scan_number(lex);
    }
    if (c == 34 /* '"' */) {
        return scan_string(lex);
    }
    // switch (c) {
    // case 40 /* '(' */:
        return make_token(lex, TOK_LPAREN, (lex_current - 1), line, col);
    // case 41 /* ')' */:
        return make_token(lex, TOK_RPAREN, (lex_current - 1), line, col);
    // case 123 /* '{' */:
        return make_token(lex, TOK_LBRACE, (lex_current - 1), line, col);
    // case 125 /* '}' */:
        return make_token(lex, TOK_RBRACE, (lex_current - 1), line, col);
    // case 91 /* '[' */:
        return make_token(lex, TOK_LBRACKET, (lex_current - 1), line, col);
    // case 93 /* ']' */:
        return make_token(lex, TOK_RBRACKET, (lex_current - 1), line, col);
    // case 44 /* ',' */:
        return make_token(lex, TOK_COMMA, (lex_current - 1), line, col);
    // case 58 /* ':' */:
        return make_token(lex, TOK_COLON, (lex_current - 1), line, col);
    // case 59 /* ';' */:
        return make_token(lex, TOK_SEMICOLON, (lex_current - 1), line, col);
    // case 46 /* '.' */:
        return make_token(lex, TOK_DOT, (lex_current - 1), line, col);
    // case /* &: */:
        if match(lex, /* &) */) {
            return make_token(lex, TOK_AND, (lex_current - 2), line, col);
        }
        return make_token(lex, TOK_AMPERSAND, (lex_current - 1), line, col);
    // case 43 /* '+' */:
        return make_token(lex, TOK_PLUS, (lex_current - 1), line, col);
    // case /* *: */:
        return make_token(lex, TOK_STAR, (lex_current - 1), line, col);
    // case 37 /* '%' */:
        return make_token(lex, TOK_PERCENT, (lex_current - 1), line, col);
    // case 47 /* '/' */:
        return make_token(lex, TOK_SLASH, (lex_current - 1), line, col);
    // case (0 - :):
        if match(lex, 62 /* '>' */) {
            return make_token(lex, TOK_ARROW, (lex_current - 2), line, col);
        }
        return make_token(lex, TOK_MINUS, (lex_current - 1), line, col);
    // case 61 /* '=' */:
        if match(lex, 61 /* '=' */) {
            return make_token(lex, TOK_EQ, (lex_current - 2), line, col);
        }
        return make_token(lex, TOK_ASSIGN, (lex_current - 1), line, col);
    // case !::
        if match(lex, 61 /* '=' */) {
            return make_token(lex, TOK_NEQ, (lex_current - 2), line, col);
        }
        return make_token(lex, TOK_NOT, (lex_current - 1), line, col);
    // case 60 /* '<' */:
        if match(lex, 61 /* '=' */) {
            return make_token(lex, TOK_LTE, (lex_current - 2), line, col);
        }
        return make_token(lex, TOK_LT, (lex_current - 1), line, col);
    // case 62 /* '>' */:
        if match(lex, 61 /* '=' */) {
            return make_token(lex, TOK_GTE, (lex_current - 2), line, col);
        }
        return make_token(lex, TOK_GT, (lex_current - 1), line, col);
    // case 124 /* '|' */:
        if match(lex, 124 /* '|' */) {
            return make_token(lex, TOK_OR, (lex_current - 2), line, col);
        }
        return error_token(lex, "unexpected '|' (did you mean '||'?)");
    // }
    return error_token(lex, "unexpected character");
}

fn lexer_peek(lex: string) -> i32 {
    var saved_current: string = lex_current;
    var saved_line: i32 = lex_line;
    var saved_col: i32 = lex_col;
    var tok: i32 = lexer_next(lex);
    lex_current = saved_current;
    lex_line = saved_line;
    lex_col = saved_col;
    return tok;
}

fn token_type_name(type: i32) -> string {
    // switch (type) {
    // case TOK_INT_LIT:
        return "integer";
    // case TOK_FLOAT_LIT:
        return "float";
    // case TOK_STRING_LIT:
        return "string";
    // case TOK_TRUE:
        return "true";
    // case TOK_FALSE:
        return "false";
    // case TOK_FN:
        return "fn";
    // case TOK_LET:
        return "let";
    // case TOK_VAR:
        return "var";
    // case TOK_STRUCT:
        return "struct";
    // case TOK_IF:
        return "if";
    // case TOK_ELSE:
        return "else";
    // case TOK_WHILE:
        return "while";
    // case TOK_RETURN:
        return "return";
    // case TOK_ALLOC:
        return "alloc";
    // case TOK_FREE:
        return "free";
    // case TOK_PTR:
        return "ptr";
    // case TOK_IDENT:
        return "identifier";
    // case TOK_U8:
        return "u8";
    // case TOK_U16:
        return "u16";
    // case TOK_U32:
        return "u32";
    // case TOK_U64:
        return "u64";
    // case TOK_I8:
        return "i8";
    // case TOK_I16:
        return "i16";
    // case TOK_I32:
        return "i32";
    // case TOK_I64:
        return "i64";
    // case TOK_F64:
        return "f64";
    // case TOK_BOOL:
        return "bool";
    // case TOK_VOID:
        return "void";
    // case TOK_PLUS:
        return "+";
    // case TOK_MINUS:
        return (0 - ;);
    // case TOK_STAR:
        return /* *; */;
    // case TOK_SLASH:
        return "/";
    // case TOK_PERCENT:
        return "%";
    // case TOK_EQ:
        return "==";
    // case TOK_NEQ:
        return "!=";
    // case TOK_LT:
        return "<";
    // case TOK_GT:
        return ">";
    // case TOK_LTE:
        return "<=";
    // case TOK_GTE:
        return ">=";
    // case TOK_AND:
        return "&&";
    // case TOK_OR:
        return "||";
    // case TOK_NOT:
        return !;;
    // case TOK_ASSIGN:
        return "=";
    // case TOK_ARROW:
        return "->";
    // case TOK_LPAREN:
        return "(";
    // case TOK_RPAREN:
        return ")";
    // case TOK_LBRACE:
        return "{";
    // case TOK_RBRACE:
        return "}";
    // case TOK_LBRACKET:
        return "[";
    // case TOK_RBRACKET:
        return "]";
    // case TOK_COMMA:
        return ",";
    // case TOK_COLON:
        return ":";
    // case TOK_SEMICOLON:
        return 0;
    // case TOK_DOT:
        return ".";
    // case TOK_AMPERSAND:
        return /* &; */;
    // case TOK_EOF:
        return "EOF";
    // case TOK_ERROR:
        return "error";
    // }
    return "unknown";
}


// ════════════════════════════════════════════════
// Source: m/bootstrap/parser.c
// ════════════════════════════════════════════════

// Auto-translated from C by Machine
// Phase 2: M reads C, writes M

fn parse_type(p: string) -> string;
fn parse_expression(p: string) -> string;
fn parse_precedence(p: string, min_prec: i32) -> string;
fn parse_postfix(p: string) -> string;
fn parse_statement(p: string) -> string;
fn parse_block(p: string) -> string;

fn ast_alloc(size: i32) -> string {
    return tohum_alloc(size);
}

fn ast_free_program(prog: string) -> i32 {
    prog;
}

fn advance_token(p: string) -> i32 {
    p_previous = p_current;
    p_current = lexer_next(/* &p_lex */);
    if (p_current_type == TOK_ERROR) {
        if !p_panic_mode {
            p_panic_mode = 1;
            p_had_error = 1;
            p_error_line = p_current_line;
            p_error_col = p_current_col;
            snprintf(p_error_msg, 0 /* sizeof(p -> error_msg) */, "lexer error: %.*s", p_current_length, p_current_start);
        }
    }
}

fn check(p: string, type: i32) -> i32 {
    return (p_current_type == type);
}

fn match(p: string, type: i32) -> i32 {
    if !check(p, type) {
        return 0;
    }
    advance_token(p);
    return 1;
}

fn error_at(p: string, msg: string) -> i32 {
    if p_panic_mode {
        return 0;
    }
    p_panic_mode = 1;
    p_had_error = 1;
    p_error_line = p_current_line;
    p_error_col = p_current_col;
    snprintf(p_error_msg, 0 /* sizeof(p -> error_msg) */, "%d:%d: %s (got '%s')", p_current_line, p_current_col, msg, token_type_name(p_current_type));
}

fn consume(p: string, type: i32, msg: string) -> i32 {
    if (p_current_type == type) {
        advance_token(p);
        return 0;
    }
    error_at(p, msg);
}

fn synchronize(p: string) -> i32 {
    p_panic_mode = 0;
    while (p_current_type != TOK_EOF) {
        if (p_previous_type == TOK_SEMICOLON) {
            return 0;
        }
        if (p_previous_type == TOK_RBRACE) {
            return 0;
        }
        // switch (p_current_type) {
        // case TOK_FN:
        // case TOK_STRUCT:
        // case TOK_LET:
        // case TOK_VAR:
        // case TOK_IF:
        // case TOK_WHILE:
        // case TOK_RETURN:
            return 0;
        // default:
            // break;
        // }
        advance_token(p);
    }
}

fn make_primitive(kind: i32, line: i32, col: i32) -> string {
    var t: string = ast_alloc_type();
    t_kind = kind;
    t_line = line;
    t_col = col;
    return t;
}

fn parse_type(p: string) -> string {
    var line: i32 = p_current_line;
    if match(p, TOK_U8) {
        return make_primitive(TYPE_U8, line, col);
    }
    if match(p, TOK_U16) {
        return make_primitive(TYPE_U16, line, col);
    }
    if match(p, TOK_U32) {
        return make_primitive(TYPE_U32, line, col);
    }
    if match(p, TOK_U64) {
        return make_primitive(TYPE_U64, line, col);
    }
    if match(p, TOK_I8) {
        return make_primitive(TYPE_I8, line, col);
    }
    if match(p, TOK_I16) {
        return make_primitive(TYPE_I16, line, col);
    }
    if match(p, TOK_I32) {
        return make_primitive(TYPE_I32, line, col);
    }
    if match(p, TOK_I64) {
        return make_primitive(TYPE_I64, line, col);
    }
    if match(p, TOK_F64) {
        return make_primitive(TYPE_F64, line, col);
    }
    if match(p, TOK_BOOL) {
        return make_primitive(TYPE_BOOL, line, col);
    }
    if match(p, TOK_VOID) {
        return make_primitive(TYPE_VOID, line, col);
    }
    if match(p, TOK_PTR) {
        consume(p, TOK_LT, "expected '<' after 'ptr'");
        var inner: string = parse_type(p);
        consume(p, TOK_GT, "expected '>' after ptr type");
        var t: string = ast_alloc_type();
        t_kind = TYPE_PTR;
        t_inner = inner;
        t_line = line;
        t_col = col;
        return t;
    }
    if match(p, TOK_LBRACKET) {
        if match(p, TOK_RBRACKET) {
            var inner: string = parse_type(p);
            var t: string = ast_alloc_type();
            t_kind = TYPE_SLICE;
            t_inner = inner;
            t_line = line;
            t_col = col;
            return t;
        }
        var inner: string = parse_type(p);
        consume(p, TOK_SEMICOLON, "expected ';' in array type");
        if !check(p, TOK_INT_LIT) {
            error_at(p, "expected array size");
            return 0 /* NULL */;
        }
        var size: i32 = p_current_int_val;
        advance_token(p);
        consume(p, TOK_RBRACKET, "expected ']' after array size");
        var t: string = ast_alloc_type();
        t_kind = TYPE_ARRAY;
        t_inner = inner;
        t_array_size = size;
        t_line = line;
        t_col = col;
        return t;
    }
    if check(p, TOK_IDENT) {
        var t: string = ast_alloc_type();
        t_kind = TYPE_NAMED;
        t_name = p_current_start;
        t_name_len = p_current_length;
        t_line = line;
        t_col = col;
        advance_token(p);
        return t;
    }
    error_at(p, "expected type");
    return 0 /* NULL */;
}

fn make_int_lit(val: i32, line: i32, col: i32) -> string {
    var e: string = ast_alloc_expr();
    e_kind = EXPR_INT_LIT;
    e_int_val = val;
    e_line = line;
    e_col = col;
    return e;
}

fn make_float_lit(val: i32, line: i32, col: i32) -> string {
    var e: string = ast_alloc_expr();
    e_kind = EXPR_FLOAT_LIT;
    e_float_val = val;
    e_line = line;
    e_col = col;
    return e;
}

fn process_escapes(s: string, len: i32, out_len: string) -> string {
    var has_escape: i32 = 0;
    var i: i32 = 0;
    while (i < len) {
        if (array_get(s, i) == 92 /* '\\' */) {
            has_escape = 1;
            // break;
        }
        i = i + 1;
    }
    if !has_escape {
        /* *out_len */ = len;
        return s;
    }
    var buf: string = ast_alloc((len + 1));
    var j: i32 = 0;
    var i: i32 = 0;
    while (i < len) {
        if ((array_get(s, i) == 92 /* '\\' */) && ((i + 1) < len)) {
            i = i + 1;
            // switch (array_get(s, i)) {
            // case 110 /* 'n' */:
                array_get(buf, j = j + 1) = 10 /* '\n' */;
                // break;
            // case 116 /* 't' */:
                array_get(buf, j = j + 1) = 9 /* '\t' */;
                // break;
            // case 114 /* 'r' */:
                array_get(buf, j = j + 1) = 13 /* '\r' */;
                // break;
            // case 92 /* '\\' */:
                array_get(buf, j = j + 1) = 92 /* '\\' */;
                // break;
            // case 34 /* '"' */:
                array_get(buf, j = j + 1) = 34 /* '"' */;
                // break;
            // case 48 /* '0' */:
                array_get(buf, j = j + 1) = 0 /* '\0' */;
                // break;
            // default:
                array_get(buf, j = j + 1) = 92 /* '\\' */;
                array_get(buf, j = j + 1) = array_get(s, i);
                // break;
            // }
        } else {
            array_get(buf, j = j + 1) = array_get(s, i);
        }
        i = i + 1;
    }
    array_get(buf, j) = 0 /* '\0' */;
    /* *out_len */ = j;
    return buf;
}

fn make_string_lit(s: string, len: i32, line: i32, col: i32) -> string {
    var processed_len: i32 = 0;
    var processed: string = process_escapes(s, len, /* &processed_len */);
    var e: string = ast_alloc_expr();
    e_kind = EXPR_STRING_LIT;
    e_str = processed;
    e_str_len = processed_len;
    e_line = line;
    e_col = col;
    return e;
}

fn make_bool_lit(val: i32, line: i32, col: i32) -> string {
    var e: string = ast_alloc_expr();
    e_kind = EXPR_BOOL_LIT;
    e_bool_val = val;
    e_line = line;
    e_col = col;
    return e;
}

fn make_ident(name: string, len: i32, line: i32, col: i32) -> string {
    var e: string = ast_alloc_expr();
    e_kind = EXPR_IDENT;
    e_ident = name;
    e_ident_len = len;
    e_line = line;
    e_col = col;
    return e;
}

fn make_binary(op: i32, lhs: string, rhs: string, line: i32, col: i32) -> string {
    var e: string = ast_alloc_expr();
    e_kind = EXPR_BINARY;
    e_bin_op = op;
    e_lhs = lhs;
    e_rhs = rhs;
    e_line = line;
    e_col = col;
    return e;
}

fn make_unary(op: i32, operand: string, line: i32, col: i32) -> string {
    var e: string = ast_alloc_expr();
    e_kind = EXPR_UNARY;
    e_unary_op = op;
    e_operand = operand;
    e_line = line;
    e_col = col;
    return e;
}

fn parse_primary(p: string) -> string {
    var line: i32 = p_current_line;
    if match(p, TOK_INT_LIT) {
        return make_int_lit(p_previous_int_val, line, col);
    }
    if match(p, TOK_FLOAT_LIT) {
        return make_float_lit(p_previous_float_val, line, col);
    }
    if match(p, TOK_STRING_LIT) {
        return make_string_lit(p_previous_start, p_previous_length, line, col);
    }
    if match(p, TOK_TRUE) {
        return make_bool_lit(1, line, col);
    }
    if match(p, TOK_FALSE) {
        return make_bool_lit(0, line, col);
    }
    if match(p, TOK_IDENT) {
        var name: string = p_previous_start;
        var name_len: i32 = p_previous_length;
        if check(p, TOK_LBRACE) {
            Lexer;
            saved_lex = p_lex;
            Token;
            saved_cur = p_current;
            Token;
            saved_prev = p_previous;
            advance_token(p);
            var is_struct_lit: i32 = 0;
            if check(p, TOK_IDENT) {
                Token;
                id = p_current;
                advance_token(p);
                if check(p, TOK_COLON) {
                    is_struct_lit = 1;
                }
                id;
            }
            p_lex = saved_lex;
            p_current = saved_cur;
            p_previous = saved_prev;
            if is_struct_lit {
                advance_token(p);
                var cap: i32 = 8;
                (FieldInit * fields) = ast_alloc((cap * 0 /* sizeof(FieldInit) */));
                var count: i32 = 0;
                while (!check(p, TOK_RBRACE) && !check(p, TOK_EOF)) {
                    if (count > 0) {
                        consume(p, TOK_COMMA, "expected ',' between fields");
                    }
                    if check(p, TOK_RBRACE) {
                        // break;
                    }
                    if !check(p, TOK_IDENT) {
                        error_at(p, "expected field name");
                        return 0 /* NULL */;
                    }
                    var fname: string = p_current_start;
                    var flen: i32 = p_current_length;
                    advance_token(p);
                    consume(p, TOK_COLON, "expected ':' after field name");
                    var val: string = parse_expression(p);
                    if (count >= cap) {
                        cap = cap * 2;
                        (FieldInit * new_fields) = ast_alloc((cap * 0 /* sizeof(FieldInit) */));
                        memcpy(new_fields, fields, (count * 0 /* sizeof(FieldInit) */));
                        fields = new_fields;
                    }
                    array_get(fields, count)_name = fname;
                    array_get(fields, count)_name_len = flen;
                    array_get(fields, count)_value = val;
                    count = count + 1;
                }
                consume(p, TOK_RBRACE, "expected '}' after struct literal");
                var e: string = ast_alloc_expr();
                e_kind = EXPR_STRUCT_LIT;
                e_struct_name = name;
                e_struct_name_len = name_len;
                e_fields = fields;
                e_field_count = count;
                e_line = line;
                e_col = col;
                return e;
            }
        }
        return make_ident(name, name_len, line, col);
    }
    if match(p, TOK_LPAREN) {
        var e: string = parse_expression(p);
        consume(p, TOK_RPAREN, "expected ')' after expression");
        return e;
    }
    error_at(p, "expected expression");
    return 0 /* NULL */;
}

fn parse_unary(p: string) -> string {
    var line: i32 = p_current_line;
    if match(p, TOK_MINUS) {
        var operand: string = parse_unary(p);
        return make_unary(UN_NEG, operand, line, col);
    }
    if match(p, TOK_NOT) {
        var operand: string = parse_unary(p);
        return make_unary(UN_NOT, operand, line, col);
    }
    if match(p, TOK_AMPERSAND) {
        var operand: string = parse_unary(p);
        return make_unary(UN_ADDR, operand, line, col);
    }
    if match(p, TOK_STAR) {
        var operand: string = parse_unary(p);
        return make_unary(UN_DEREF, operand, line, col);
    }
    return parse_postfix(p);
}

fn parse_postfix(p: string) -> string {
    var left: string = parse_primary(p);
    if p_had_error {
        return left;
    }
    while true {
        var line: i32 = p_current_line;
        if check(p, TOK_LPAREN) {
            advance_token(p);
            var cap: i32 = 8;
            var args: string = ast_alloc((cap * 0 /* sizeof(Expr *) */));
            var count: i32 = 0;
            while (!check(p, TOK_RPAREN) && !check(p, TOK_EOF)) {
                if (count > 0) {
                    consume(p, TOK_COMMA, "expected ',' between arguments");
                }
                if (count >= cap) {
                    cap = cap * 2;
                    var new_args: string = ast_alloc((cap * 0 /* sizeof(Expr *) */));
                    memcpy(new_args, args, (count * 0 /* sizeof(Expr *) */));
                    args = new_args;
                }
                array_get(args, count) = parse_expression(p);
                count = count + 1;
            }
            consume(p, TOK_RPAREN, "expected ')' after arguments");
            var e: string = ast_alloc_expr();
            e_kind = EXPR_CALL;
            e_callee = left;
            e_args = args;
            e_arg_count = count;
            e_line = line;
            e_col = col;
            left = e;
            // continue;
        }
        if check(p, TOK_DOT) {
            advance_token(p);
            if !check(p, TOK_IDENT) {
                error_at(p, "expected member name after '.'");
                return left;
            }
            var e: string = ast_alloc_expr();
            e_kind = EXPR_MEMBER;
            e_object = left;
            e_member = p_current_start;
            e_member_len = p_current_length;
            e_line = line;
            e_col = col;
            advance_token(p);
            left = e;
            // continue;
        }
        if check(p, TOK_LBRACKET) {
            advance_token(p);
            var idx: string = parse_expression(p);
            consume(p, TOK_RBRACKET, "expected ']' after index");
            var e: string = ast_alloc_expr();
            e_kind = EXPR_INDEX;
            e_target = left;
            e_index_expr = idx;
            e_line = line;
            e_col = col;
            left = e;
            // continue;
        }
        // break;
    }
    return left;
}

fn get_precedence(type: i32) -> i32 {
    // switch (type) {
    // case TOK_OR:
        return PREC_OR;
    // case TOK_AND:
        return PREC_AND;
    // case TOK_EQ:
    // case TOK_NEQ:
        return PREC_EQUALITY;
    // case TOK_LT:
    // case TOK_GT:
    // case TOK_LTE:
    // case TOK_GTE:
        return PREC_COMPARE;
    // case TOK_PLUS:
    // case TOK_MINUS:
        return PREC_TERM;
    // case TOK_STAR:
    // case TOK_SLASH:
    // case TOK_PERCENT:
        return PREC_FACTOR;
    // default:
        return PREC_NONE;
    // }
}

fn token_to_binop(type: i32) -> i32 {
    // switch (type) {
    // case TOK_PLUS:
        return BIN_ADD;
    // case TOK_MINUS:
        return BIN_SUB;
    // case TOK_STAR:
        return BIN_MUL;
    // case TOK_SLASH:
        return BIN_DIV;
    // case TOK_PERCENT:
        return BIN_MOD;
    // case TOK_EQ:
        return BIN_EQ;
    // case TOK_NEQ:
        return BIN_NEQ;
    // case TOK_LT:
        return BIN_LT;
    // case TOK_GT:
        return BIN_GT;
    // case TOK_LTE:
        return BIN_LTE;
    // case TOK_GTE:
        return BIN_GTE;
    // case TOK_AND:
        return BIN_AND;
    // case TOK_OR:
        return BIN_OR;
    // default:
        return BIN_ADD;
    // }
}

fn parse_precedence(p: string, min_prec: i32) -> string {
    var left: string = parse_unary(p);
    if p_had_error {
        return left;
    }
    while true {
        var prec: i32 = get_precedence(p_current_type);
        if (prec < min_prec) {
            // break;
        }
        var line: i32 = p_current_line;
        var op: i32 = token_to_binop(p_current_type);
        advance_token(p);
        var right: string = parse_precedence(p, (prec + 1));
        left = make_binary(op, left, right, line, col);
    }
    return left;
}

fn parse_expression(p: string) -> string {
    return parse_precedence(p, PREC_OR);
}

fn parse_block(p: string) -> string {
    var line: i32 = p_current_line;
    consume(p, TOK_LBRACE, "expected '{'");
    var cap: i32 = 16;
    var stmts: string = ast_alloc((cap * 0 /* sizeof(Stmt *) */));
    var count: i32 = 0;
    while (!check(p, TOK_RBRACE) && !check(p, TOK_EOF)) {
        var s: string = parse_statement(p);
        if p_had_error {
            synchronize(p);
            // continue;
        }
        if s {
            if (count >= cap) {
                cap = cap * 2;
                var new_stmts: string = ast_alloc((cap * 0 /* sizeof(Stmt *) */));
                memcpy(new_stmts, stmts, (count * 0 /* sizeof(Stmt *) */));
                stmts = new_stmts;
            }
            array_get(stmts, count = count + 1) = s;
        }
    }
    consume(p, TOK_RBRACE, "expected '}'");
    var block: string = ast_alloc_stmt();
    block_kind = STMT_BLOCK;
    block_stmts = stmts;
    block_stmt_count = count;
    block_line = line;
    block_col = col;
    return block;
}

fn parse_let_var(p: string, is_var: i32) -> string {
    var line: i32 = p_previous_line;
    if !check(p, TOK_IDENT) {
        error_at(p, "expected variable name");
        return 0 /* NULL */;
    }
    var name: string = p_current_start;
    var name_len: i32 = p_current_length;
    advance_token(p);
    var type: string = 0 /* NULL */;
    if match(p, TOK_COLON) {
        type = parse_type(p);
    }
    var init: string = 0 /* NULL */;
    if match(p, TOK_ASSIGN) {
        init = parse_expression(p);
    }
    consume(p, TOK_SEMICOLON, "expected ';' after declaration");
    var s: string = ast_alloc_stmt();
    if is_var {
        s_kind = STMT_VAR;
    } else {
        s_kind = STMT_LET;
    }
    s_var_name = name;
    s_var_name_len = name_len;
    s_var_type = type;
    s_var_init = init;
    s_line = line;
    s_col = col;
    return s;
}

fn parse_return(p: string) -> string {
    var line: i32 = p_previous_line;
    var expr: string = 0 /* NULL */;
    if !check(p, TOK_SEMICOLON) {
        expr = parse_expression(p);
    }
    consume(p, TOK_SEMICOLON, "expected ';' after return");
    var s: string = ast_alloc_stmt();
    s_kind = STMT_RETURN;
    s_ret_expr = expr;
    s_line = line;
    s_col = col;
    return s;
}

fn parse_if(p: string) -> string {
    var line: i32 = p_previous_line;
    var cond: string = parse_expression(p);
    var then_block: string = parse_block(p);
    var else_block: string = 0 /* NULL */;
    if match(p, TOK_ELSE) {
        if check(p, TOK_IF) {
            advance_token(p);
            else_block = parse_if(p);
        } else {
            else_block = parse_block(p);
        }
    }
    var s: string = ast_alloc_stmt();
    s_kind = STMT_IF;
    s_if_cond = cond;
    s_if_then = then_block;
    s_if_else = else_block;
    s_line = line;
    s_col = col;
    return s;
}

fn parse_while(p: string) -> string {
    var line: i32 = p_previous_line;
    var cond: string = parse_expression(p);
    var body: string = parse_block(p);
    var s: string = ast_alloc_stmt();
    s_kind = STMT_WHILE;
    s_while_cond = cond;
    s_while_body = body;
    s_line = line;
    s_col = col;
    return s;
}

fn parse_free(p: string) -> string {
    var line: i32 = p_previous_line;
    consume(p, TOK_LPAREN, "expected '(' after 'free'");
    var expr: string = parse_expression(p);
    consume(p, TOK_RPAREN, "expected ')' after free argument");
    consume(p, TOK_SEMICOLON, "expected ';' after free");
    var s: string = ast_alloc_stmt();
    s_kind = STMT_FREE;
    s_free_expr = expr;
    s_line = line;
    s_col = col;
    return s;
}

fn parse_statement(p: string) -> string {
    if match(p, TOK_LET) {
        return parse_let_var(p, 0);
    }
    if match(p, TOK_VAR) {
        return parse_let_var(p, 1);
    }
    if match(p, TOK_RETURN) {
        return parse_return(p);
    }
    if match(p, TOK_IF) {
        return parse_if(p);
    }
    if match(p, TOK_WHILE) {
        return parse_while(p);
    }
    if match(p, TOK_FREE) {
        return parse_free(p);
    }
    if check(p, TOK_LBRACE) {
        return parse_block(p);
    }
    var line: i32 = p_current_line;
    var expr: string = parse_expression(p);
    if match(p, TOK_ASSIGN) {
        var value: string = parse_expression(p);
        consume(p, TOK_SEMICOLON, "expected ';' after assignment");
        var s: string = ast_alloc_stmt();
        s_kind = STMT_ASSIGN;
        s_assign_target = expr;
        s_assign_value = value;
        s_line = line;
        s_col = col;
        return s;
    }
    consume(p, TOK_SEMICOLON, "expected ';' after expression");
    var s: string = ast_alloc_stmt();
    s_kind = STMT_EXPR;
    s_expr = expr;
    s_line = line;
    s_col = col;
    return s;
}

fn parse_fn(p: string) -> string {
    var line: i32 = p_previous_line;
    if !check(p, TOK_IDENT) {
        error_at(p, "expected function name");
        return 0 /* NULL */;
    }
    var name: string = p_current_start;
    var name_len: i32 = p_current_length;
    advance_token(p);
    consume(p, TOK_LPAREN, "expected '(' after function name");
    var cap: i32 = 8;
    (Param * params) = ast_alloc((cap * 0 /* sizeof(Param) */));
    var count: i32 = 0;
    while (!check(p, TOK_RPAREN) && !check(p, TOK_EOF)) {
        if (count > 0) {
            consume(p, TOK_COMMA, "expected ',' between parameters");
        }
        if !check(p, TOK_IDENT) {
            error_at(p, "expected parameter name");
            return 0 /* NULL */;
        }
        Param;
        param;
        param_name = p_current_start;
        param_name_len = p_current_length;
        advance_token(p);
        consume(p, TOK_COLON, "expected ':' after parameter name");
        param_type = parse_type(p);
        if (count >= cap) {
            cap = cap * 2;
            (Param * new_params) = ast_alloc((cap * 0 /* sizeof(Param) */));
            memcpy(new_params, params, (count * 0 /* sizeof(Param) */));
            params = new_params;
        }
        array_get(params, count = count + 1) = param;
    }
    consume(p, TOK_RPAREN, "expected ')' after parameters");
    var ret_type: string = 0 /* NULL */;
    if match(p, TOK_ARROW) {
        ret_type = parse_type(p);
    }
    var body: string = 0 /* NULL */;
    if match(p, TOK_SEMICOLON) {
        body = 0 /* NULL */;
    } else {
        body = parse_block(p);
    }
    var d: string = ast_alloc_decl();
    d_kind = DECL_FN;
    d_fn_name = name;
    d_fn_name_len = name_len;
    d_params = params;
    d_param_count = count;
    d_return_type = ret_type;
    d_fn_body = body;
    d_line = line;
    d_col = col;
    return d;
}

fn parse_struct(p: string) -> string {
    var line: i32 = p_previous_line;
    if !check(p, TOK_IDENT) {
        error_at(p, "expected struct name");
        return 0 /* NULL */;
    }
    var name: string = p_current_start;
    var name_len: i32 = p_current_length;
    advance_token(p);
    consume(p, TOK_LBRACE, "expected '{' after struct name");
    var cap: i32 = 8;
    (StructField * fields) = ast_alloc((cap * 0 /* sizeof(StructField) */));
    var count: i32 = 0;
    while (!check(p, TOK_RBRACE) && !check(p, TOK_EOF)) {
        if !check(p, TOK_IDENT) {
            error_at(p, "expected field name");
            return 0 /* NULL */;
        }
        StructField;
        field;
        field_name = p_current_start;
        field_name_len = p_current_length;
        advance_token(p);
        consume(p, TOK_COLON, "expected ':' after field name");
        field_type = parse_type(p);
        if (count >= cap) {
            cap = cap * 2;
            (StructField * new_fields) = ast_alloc((cap * 0 /* sizeof(StructField) */));
            memcpy(new_fields, fields, (count * 0 /* sizeof(StructField) */));
            fields = new_fields;
        }
        array_get(fields, count = count + 1) = field;
        if !check(p, TOK_RBRACE) {
            consume(p, TOK_COMMA, "expected ',' after field");
        }
    }
    consume(p, TOK_RBRACE, "expected '}' after struct fields");
    var d: string = ast_alloc_decl();
    d_kind = DECL_STRUCT;
    d_st_name = name;
    d_st_name_len = name_len;
    d_st_fields = fields;
    d_st_field_count = count;
    d_line = line;
    d_col = col;
    return d;
}

fn parse_global_var(p: string) -> string {
    var line: i32 = p_current_line;
    var col: i32 = p_current_col;
    var name: string = p_current_start;
    var name_len: i32 = p_current_length;
    consume(p, TOK_IDENT, "expected variable name");
    var type: string = 0 /* NULL */;
    if match(p, TOK_COLON) {
        type = parse_type(p);
    }
    var init: string = 0 /* NULL */;
    if match(p, TOK_ASSIGN) {
        init = parse_expression(p);
    }
    consume(p, TOK_SEMICOLON, "expected ';' after global var");
    var d: string = ast_alloc_decl();
    d_kind = DECL_VAR;
    d_gv_name = name;
    d_gv_name_len = name_len;
    d_gv_type = type;
    d_gv_init = init;
    d_line = line;
    d_col = col;
    return d;
}

fn parse_declaration(p: string) -> string {
    if match(p, TOK_FN) {
        return parse_fn(p);
    }
    if match(p, TOK_STRUCT) {
        return parse_struct(p);
    }
    if match(p, TOK_VAR) {
        return parse_global_var(p);
    }
    error_at(p, "expected 'fn', 'struct', or 'var' at top level");
    return 0 /* NULL */;
}

fn parser_init(p: string, source: string) -> i32 {
    lexer_init(/* &p_lex */, source);
    p_had_error = 0;
    p_panic_mode = 0;
    array_get(p_error_msg, 0) = 0 /* '\0' */;
    p_error_line = 0;
    p_error_col = 0;
    advance_token(p);
}

fn parser_parse(p: string) -> string {
    var cap: i32 = 16;
    var decls: string = ast_alloc((cap * 0 /* sizeof(Decl *) */));
    var count: i32 = 0;
    while !check(p, TOK_EOF) {
        var d: string = parse_declaration(p);
        if p_had_error {
            synchronize(p);
            // continue;
        }
        if d {
            if (count >= cap) {
                cap = cap * 2;
                var new_decls: string = ast_alloc((cap * 0 /* sizeof(Decl *) */));
                memcpy(new_decls, decls, (count * 0 /* sizeof(Decl *) */));
                decls = new_decls;
            }
            array_get(decls, count = count + 1) = d;
        }
    }
    if p_had_error {
        return 0 /* NULL */;
    }
    var prog: string = ast_alloc(0 /* sizeof(Program) */);
    prog_decls = decls;
    prog_decl_count = count;
    return prog;
}

fn parser_parse_expr(p: string) -> string {
    return parse_expression(p);
}

fn parser_parse_stmt(p: string) -> string {
    return parse_statement(p);
}

fn parser_had_error(p: string) -> i32 {
    return p_had_error;
}

fn parser_error(p: string) -> string {
    return p_error_msg;
}


// ════════════════════════════════════════════════
// Source: m/bootstrap/codegen.c
// ════════════════════════════════════════════════

// Auto-translated from C by Machine
// Phase 2: M reads C, writes M

fn gen_expr(ctx: string, e: string) -> i32;
fn gen_stmt(ctx: string, s: string) -> i32;

fn error(ctx: string, line: i32, msg: string) -> i32 {
    if ctx_compiler_had_error {
        return 0;
    }
    ctx_compiler_had_error = 1;
    ctx_compiler_error_line = line;
    snprintf(ctx_compiler_error_msg, 0 /* sizeof(ctx -> compiler -> error_msg) */, "line %d: %s", line, msg);
}

fn resolve_local(ctx: string, name: string, len: i32) -> i32 {
    var i: i32 = (ctx_local_count - 1);
    while (i >= 0) {
        if ((array_get(ctx_locals, i)_name_len == len) && (memcmp(array_get(ctx_locals, i)_name, name, len) == 0)) {
            return array_get(ctx_locals, i)_slot;
        }
        i = i - 1;
    }
    return (0 - 1);
}

fn add_local(ctx: string, name: string, name_len: i32, line: i32) -> i32 {
    if (ctx_local_count >= MAX_LOCALS) {
        error(ctx, line, "too many local variables");
        return (0 - 1);
    }
    var slot: i32 = ctx_local_count;
    var local: string = /* &array_get(ctx_locals, ctx_local_count = ctx_local_count + 1) */;
    local_name = name;
    local_name_len = name_len;
    local_slot = slot;
    local_depth = ctx_scope_depth;
    if (ctx_local_count > ctx_max_local_count) {
        ctx_max_local_count = ctx_local_count;
    }
    return slot;
}

fn begin_scope(ctx: string) -> i32 {
    ctx_scope_depth = ctx_scope_depth + 1;
}

fn end_scope(ctx: string) -> i32 {
    while ((ctx_local_count > 0) && (array_get(ctx_locals, (ctx_local_count - 1))_depth == ctx_scope_depth)) {
        ctx_local_count = ctx_local_count - 1;
    }
    ctx_scope_depth = ctx_scope_depth - 1;
}

fn emit(ctx: string, op: i32, line: i32) -> i32 {
    chunk_write(ctx_chunk, op, line);
}

fn emit_u16(ctx: string, val: i32, line: i32) -> i32 {
    chunk_write_u16(ctx_chunk, val, line);
}

fn emit_jump(ctx: string, op: i32, line: i32) -> i32 {
    emit(ctx, op, line);
    var offset: i32 = ctx_chunk_code_len;
    emit_u16(ctx, 0, line);
    return offset;
}

fn patch_jump(ctx: string, offset: i32) -> i32 {
    var jump: i32 = ((ctx_chunk_code_len - offset) - 2);
    if ((jump > 32767) || (jump < (0 - 32768))) {
        error(ctx, 0, "jump too far");
        return 0;
    }
    chunk_patch_i16(ctx_chunk, offset, jump);
}

fn find_function(c: string, name: string, len: i32) -> i32 {
    var i: i32 = 0;
    while (i < c_module_func_count) {
        if ((array_get(c_module_functions, i)_name_len == len) && (memcmp(array_get(c_module_functions, i)_name, name, len) == 0)) {
            return i;
        }
        i = i + 1;
    }
    return (0 - 1);
}

fn gen_expr(ctx: string, e: string) -> i32 {
    if !e {
        return 0;
    }
    // switch (e_kind) {
    // case EXPR_INT_LIT:
        var idx: i32 = chunk_add_int(ctx_chunk, e_int_val);
        emit(ctx, OP_CONST_INT, e_line);
        emit_u16(ctx, idx, e_line);
        // break;
    // case EXPR_FLOAT_LIT:
        var idx: i32 = chunk_add_float(ctx_chunk, e_float_val);
        emit(ctx, OP_CONST_FLOAT, e_line);
        emit_u16(ctx, idx, e_line);
        // break;
    // case EXPR_STRING_LIT:
        var idx: i32 = chunk_add_string(ctx_chunk, e_str, e_str_len);
        emit(ctx, OP_CONST_STRING, e_line);
        emit_u16(ctx, idx, e_line);
        // break;
    // case EXPR_BOOL_LIT:
        emit(ctx, /* e_bool_val ? OP_TRUE : OP_FALSE */, e_line);
        // break;
    // case EXPR_IDENT:
        var slot: i32 = resolve_local(ctx, e_ident, e_ident_len);
        if (slot >= 0) {
            emit(ctx, OP_LOCAL_GET, e_line);
            emit_u16(ctx, slot, e_line);
        } else {
            var fi: i32 = find_function(ctx_compiler, e_ident, e_ident_len);
            if (fi >= 0) {
                var idx: i32 = chunk_add_int(ctx_chunk, fi);
                emit(ctx, OP_CONST_INT, e_line);
                emit_u16(ctx, idx, e_line);
            } else {
                var ni: i32 = module_add_name(/* &ctx_compiler_module */, e_ident, e_ident_len);
                emit(ctx, OP_GLOBAL_GET, e_line);
                emit_u16(ctx, ni, e_line);
            }
        }
        // break;
    // case EXPR_BINARY:
        if (e_bin_op == BIN_AND) {
            gen_expr(ctx, e_lhs);
            var skip: i32 = emit_jump(ctx, OP_JUMP_FALSE, e_line);
            gen_expr(ctx, e_rhs);
            var end: i32 = emit_jump(ctx, OP_JUMP, e_line);
            patch_jump(ctx, skip);
            emit(ctx, OP_FALSE, e_line);
            patch_jump(ctx, end);
            // break;
        }
        if (e_bin_op == BIN_OR) {
            gen_expr(ctx, e_lhs);
            var try_right: i32 = emit_jump(ctx, OP_JUMP_FALSE, e_line);
            emit(ctx, OP_TRUE, e_line);
            var end: i32 = emit_jump(ctx, OP_JUMP, e_line);
            patch_jump(ctx, try_right);
            gen_expr(ctx, e_rhs);
            patch_jump(ctx, end);
            // break;
        }
        gen_expr(ctx, e_lhs);
        gen_expr(ctx, e_rhs);
        // switch (e_bin_op) {
        // case BIN_ADD:
            emit(ctx, OP_ADD, e_line);
            // break;
        // case BIN_SUB:
            emit(ctx, OP_SUB, e_line);
            // break;
        // case BIN_MUL:
            emit(ctx, OP_MUL, e_line);
            // break;
        // case BIN_DIV:
            emit(ctx, OP_DIV, e_line);
            // break;
        // case BIN_MOD:
            emit(ctx, OP_MOD, e_line);
            // break;
        // case BIN_EQ:
            emit(ctx, OP_EQ, e_line);
            // break;
        // case BIN_NEQ:
            emit(ctx, OP_NEQ, e_line);
            // break;
        // case BIN_LT:
            emit(ctx, OP_LT, e_line);
            // break;
        // case BIN_GT:
            emit(ctx, OP_GT, e_line);
            // break;
        // case BIN_LTE:
            emit(ctx, OP_LTE, e_line);
            // break;
        // case BIN_GTE:
            emit(ctx, OP_GTE, e_line);
            // break;
        // default:
            // break;
        // }
        // break;
    // case EXPR_UNARY:
        gen_expr(ctx, e_operand);
        // switch (e_unary_op) {
        // case UN_NEG:
            emit(ctx, OP_NEG, e_line);
            // break;
        // case UN_NOT:
            emit(ctx, OP_NOT, e_line);
            // break;
        // case UN_ADDR:
            // break;
        // case UN_DEREF:
            emit(ctx, OP_LOAD, e_line);
            // break;
        // default:
            // break;
        // }
        // break;
    // case EXPR_CALL:
        if (e_callee_kind == EXPR_IDENT) {
            var name: string = e_callee_ident;
            var nlen: i32 = e_callee_ident_len;
            if ((nlen == 5) && (memcmp(name, "print", 5) == 0)) {
                if (e_arg_count >= 1) {
                    gen_expr(ctx, array_get(e_args, 0));
                    emit(ctx, OP_PRINT, e_line);
                }
                emit(ctx, OP_NIL, e_line);
                // break;
            }
            if ((nlen == 3) && (memcmp(name, "len", 3) == 0)) {
                if (e_arg_count >= 1) {
                    gen_expr(ctx, array_get(e_args, 0));
                }
                emit(ctx, OP_BUILTIN_LEN, e_line);
                // break;
            }
            if ((nlen == 7) && (memcmp(name, "char_at", 7) == 0)) {
                if (e_arg_count >= 2) {
                    gen_expr(ctx, array_get(e_args, 0));
                    gen_expr(ctx, array_get(e_args, 1));
                }
                emit(ctx, OP_BUILTIN_CHAR_AT, e_line);
                // break;
            }
            if ((nlen == 6) && (memcmp(name, "substr", 6) == 0)) {
                if (e_arg_count >= 3) {
                    gen_expr(ctx, array_get(e_args, 0));
                    gen_expr(ctx, array_get(e_args, 1));
                    gen_expr(ctx, array_get(e_args, 2));
                }
                emit(ctx, OP_BUILTIN_SUBSTR, e_line);
                // break;
            }
            if ((nlen == 10) && (memcmp(name, "str_concat", 10) == 0)) {
                if (e_arg_count >= 2) {
                    gen_expr(ctx, array_get(e_args, 0));
                    gen_expr(ctx, array_get(e_args, 1));
                }
                emit(ctx, OP_BUILTIN_STR_CONCAT, e_line);
                // break;
            }
            if ((nlen == 10) && (memcmp(name, "int_to_str", 10) == 0)) {
                if (e_arg_count >= 1) {
                    gen_expr(ctx, array_get(e_args, 0));
                }
                emit(ctx, OP_BUILTIN_INT_TO_STR, e_line);
                // break;
            }
            if ((nlen == 6) && (memcmp(name, "str_eq", 6) == 0)) {
                if (e_arg_count >= 2) {
                    gen_expr(ctx, array_get(e_args, 0));
                    gen_expr(ctx, array_get(e_args, 1));
                }
                emit(ctx, OP_BUILTIN_STR_EQ, e_line);
                // break;
            }
            if ((nlen == 9) && (memcmp(name, "array_new", 9) == 0)) {
                if (e_arg_count >= 1) {
                    gen_expr(ctx, array_get(e_args, 0));
                }
                emit(ctx, OP_ARRAY_NEW, e_line);
                emit_u16(ctx, 0, e_line);
                // break;
            }
            if ((nlen == 9) && (memcmp(name, "array_get", 9) == 0)) {
                if (e_arg_count >= 2) {
                    gen_expr(ctx, array_get(e_args, 0));
                    gen_expr(ctx, array_get(e_args, 1));
                }
                emit(ctx, OP_ARRAY_GET, e_line);
                // break;
            }
            if ((nlen == 9) && (memcmp(name, "array_set", 9) == 0)) {
                if (e_arg_count >= 3) {
                    gen_expr(ctx, array_get(e_args, 0));
                    gen_expr(ctx, array_get(e_args, 1));
                    gen_expr(ctx, array_get(e_args, 2));
                }
                emit(ctx, OP_ARRAY_SET, e_line);
                emit(ctx, OP_NIL, e_line);
                // break;
            }
            if ((nlen == 9) && (memcmp(name, "array_len", 9) == 0)) {
                if (e_arg_count >= 1) {
                    gen_expr(ctx, array_get(e_args, 0));
                }
                emit(ctx, OP_ARRAY_LEN, e_line);
                // break;
            }
            if ((nlen == 10) && (memcmp(name, "array_push", 10) == 0)) {
                if (e_arg_count >= 2) {
                    gen_expr(ctx, array_get(e_args, 0));
                    gen_expr(ctx, array_get(e_args, 1));
                }
                emit(ctx, OP_ARRAY_PUSH, e_line);
                emit(ctx, OP_NIL, e_line);
                // break;
            }
            if ((nlen == 9) && (memcmp(name, "read_file", 9) == 0)) {
                if (e_arg_count >= 1) {
                    gen_expr(ctx, array_get(e_args, 0));
                }
                emit(ctx, OP_BUILTIN_READ_FILE, e_line);
                // break;
            }
            if ((nlen == 11) && (memcmp(name, "char_to_str", 11) == 0)) {
                if (e_arg_count >= 1) {
                    gen_expr(ctx, array_get(e_args, 0));
                }
                emit(ctx, OP_BUILTIN_CHAR_TO_STR, e_line);
                // break;
            }
            if ((nlen == 4) && (memcmp(name, "argc", 4) == 0)) {
                emit(ctx, OP_BUILTIN_ARGC, e_line);
                // break;
            }
            if ((nlen == 4) && (memcmp(name, "argv", 4) == 0)) {
                if (e_arg_count >= 1) {
                    gen_expr(ctx, array_get(e_args, 0));
                }
                emit(ctx, OP_BUILTIN_ARGV, e_line);
                // break;
            }
            if ((nlen == 10) && (memcmp(name, "write_file", 10) == 0)) {
                if (e_arg_count >= 2) {
                    gen_expr(ctx, array_get(e_args, 0));
                    gen_expr(ctx, array_get(e_args, 1));
                }
                emit(ctx, OP_BUILTIN_WRITE_FILE, e_line);
                // break;
            }
            if ((nlen == 7) && (memcmp(name, "println", 7) == 0)) {
                if (e_arg_count >= 1) {
                    gen_expr(ctx, array_get(e_args, 0));
                    emit(ctx, OP_PRINT, e_line);
                }
                var idx: i32 = chunk_add_string(ctx_chunk, "\n", 1);
                emit(ctx, OP_CONST_STRING, e_line);
                emit_u16(ctx, idx, e_line);
                emit(ctx, OP_PRINT, e_line);
                emit(ctx, OP_NIL, e_line);
                // break;
            }
        }
        gen_expr(ctx, e_callee);
        var i: i32 = 0;
        while (i < e_arg_count) {
            gen_expr(ctx, array_get(e_args, i));
            i = i + 1;
        }
        emit(ctx, OP_CALL, e_line);
        emit_u16(ctx, e_arg_count, e_line);
        // break;
    // case EXPR_MEMBER:
        gen_expr(ctx, e_object);
        var fi: i32 = chunk_add_string(ctx_chunk, e_member, e_member_len);
        emit(ctx, OP_FIELD_GET, e_line);
        emit_u16(ctx, fi, e_line);
        // break;
    // case EXPR_INDEX:
        gen_expr(ctx, e_target);
        gen_expr(ctx, e_index_expr);
        emit(ctx, OP_LOAD, e_line);
        // break;
    // case EXPR_STRUCT_LIT:
        var i: i32 = 0;
        while (i < e_field_count) {
            gen_expr(ctx, array_get(e_fields, i)_value);
            i = i + 1;
        }
        var ti: i32 = chunk_add_string(ctx_chunk, e_struct_name, e_struct_name_len);
        emit(ctx, OP_STRUCT_NEW, e_line);
        emit_u16(ctx, ti, e_line);
        emit_u16(ctx, e_field_count, e_line);
        // break;
    // }
}

fn gen_stmt(ctx: string, s: string) -> i32 {
    if !s {
        return 0;
    }
    // switch (s_kind) {
    // case STMT_LET:
    // case STMT_VAR:
        if s_var_init {
            gen_expr(ctx, s_var_init);
        } else {
            emit(ctx, OP_NIL, s_line);
        }
        var slot: i32 = add_local(ctx, s_var_name, s_var_name_len, s_line);
        emit(ctx, OP_LOCAL_SET, s_line);
        emit_u16(ctx, slot, s_line);
        emit(ctx, OP_POP, s_line);
        // break;
    // case STMT_RETURN:
        if s_ret_expr {
            gen_expr(ctx, s_ret_expr);
        } else {
            emit(ctx, OP_NIL, s_line);
        }
        emit(ctx, OP_RETURN, s_line);
        // break;
    // case STMT_IF:
        gen_expr(ctx, s_if_cond);
        var else_jump: i32 = emit_jump(ctx, OP_JUMP_FALSE, s_line);
        gen_stmt(ctx, s_if_then);
        if s_if_else {
            var end_jump: i32 = emit_jump(ctx, OP_JUMP, s_line);
            patch_jump(ctx, else_jump);
            gen_stmt(ctx, s_if_else);
            patch_jump(ctx, end_jump);
        } else {
            patch_jump(ctx, else_jump);
        }
        // break;
    // case STMT_WHILE:
        var loop_start: i32 = ctx_chunk_code_len;
        gen_expr(ctx, s_while_cond);
        var exit_jump: i32 = emit_jump(ctx, OP_JUMP_FALSE, s_line);
        gen_stmt(ctx, s_while_body);
        emit(ctx, OP_JUMP, s_line);
        var back: i32 = ctx_chunk_code_len;
        emit_u16(ctx, 0, s_line);
        var offset: i32 = ((loop_start - back) - 2);
        chunk_patch_i16(ctx_chunk, back, offset);
        patch_jump(ctx, exit_jump);
        // break;
    // case STMT_BLOCK:
        begin_scope(ctx);
        var i: i32 = 0;
        while (i < s_stmt_count) {
            gen_stmt(ctx, array_get(s_stmts, i));
            i = i + 1;
        }
        end_scope(ctx);
        // break;
    // case STMT_ASSIGN:
        gen_expr(ctx, s_assign_value);
        if (s_assign_target_kind == EXPR_IDENT) {
            var slot: i32 = resolve_local(ctx, s_assign_target_ident, s_assign_target_ident_len);
            if (slot >= 0) {
                emit(ctx, OP_LOCAL_SET, s_line);
                emit_u16(ctx, slot, s_line);
            } else {
                var ni: i32 = module_add_name(/* &ctx_compiler_module */, s_assign_target_ident, s_assign_target_ident_len);
                emit(ctx, OP_GLOBAL_SET, s_line);
                emit_u16(ctx, ni, s_line);
            }
        } else         if (s_assign_target_kind == EXPR_MEMBER) {
            gen_expr(ctx, s_assign_target_object);
            var fi: i32 = chunk_add_string(ctx_chunk, s_assign_target_member, s_assign_target_member_len);
            emit(ctx, OP_FIELD_SET, s_line);
            emit_u16(ctx, fi, s_line);
        }
        emit(ctx, OP_POP, s_line);
        // break;
    // case STMT_EXPR:
        gen_expr(ctx, s_expr);
        emit(ctx, OP_POP, s_line);
        // break;
    // case STMT_FREE:
        gen_expr(ctx, s_free_expr);
        emit(ctx, OP_FREE, s_line);
        // break;
    // }
}

fn gen_function(c: string, d: string) -> i32 {
    var fi: i32 = find_function(c, d_fn_name, d_fn_name_len);
    if (fi < 0) {
        Function;
        fn;
        memset(/* &fn */, 0, 0 /* sizeof(fn) */);
        fn_name = d_fn_name;
        fn_name_len = d_fn_name_len;
        fn_param_count = d_param_count;
        chunk_init(/* &fn_chunk */);
        fi = module_add_function(/* &c_module */, fn);
    } else {
        chunk_free(/* &array_get(c_module_functions, fi)_chunk */);
        chunk_init(/* &array_get(c_module_functions, fi)_chunk */);
    }
    var ctx: i32 = 0;
    memset(/* &ctx */, 0, 0 /* sizeof(ctx) */);
    ctx_compiler = c;
    ctx_chunk = /* &array_get(c_module_functions, fi)_chunk */;
    ctx_scope_depth = 0;
    ctx_func_index = fi;
    var i: i32 = 0;
    while (i < d_param_count) {
        add_local(/* &ctx */, array_get(d_params, i)_name, array_get(d_params, i)_name_len, d_line);
        i = i + 1;
    }
    if (d_fn_body && (d_fn_body_kind == STMT_BLOCK)) {
        var i: i32 = 0;
        while (i < d_fn_body_stmt_count) {
            gen_stmt(/* &ctx */, array_get(d_fn_body_stmts, i));
            i = i + 1;
        }
    }
    emit(/* &ctx */, OP_NIL, d_line);
    emit(/* &ctx */, OP_RETURN, d_line);
    array_get(c_module_functions, fi)_local_count = ctx_max_local_count;
}

fn compiler_init(c: string) -> i32 {
    memset(c, 0, 0 /* sizeof(Compiler) */);
    module_init(/* &c_module */);
}

fn compiler_compile(c: string, prog: string) -> i32 {
    if !prog {
        return (0 - 1);
    }
    var i: i32 = 0;
    while (i < prog_decl_count) {
        if (array_get(prog_decls, i)_kind == DECL_FN) {
            var d: string = array_get(prog_decls, i);
            Function;
            placeholder;
            memset(/* &placeholder */, 0, 0 /* sizeof(placeholder) */);
            placeholder_name = d_fn_name;
            placeholder_name_len = d_fn_name_len;
            placeholder_param_count = d_param_count;
            chunk_init(/* &placeholder_chunk */);
            module_add_function(/* &c_module */, placeholder);
        }
        i = i + 1;
    }
    var i: i32 = 0;
    while (i < prog_decl_count) {
        if (array_get(prog_decls, i)_kind == DECL_VAR) {
            module_add_name(/* &c_module */, array_get(prog_decls, i)_gv_name, array_get(prog_decls, i)_gv_name_len);
        }
        i = i + 1;
    }
    var has_globals: i32 = 0;
    var i: i32 = 0;
    while (i < prog_decl_count) {
        var d: string = array_get(prog_decls, i);
        // switch (d_kind) {
        // case DECL_FN:
            if d_fn_body {
                gen_function(c, d);
            }
            // break;
        // case DECL_STRUCT:
            // break;
        // case DECL_VAR:
            has_globals = 1;
            // break;
        // }
        if c_had_error {
            return (0 - 1);
        }
        i = i + 1;
    }
    if has_globals {
        Function;
        init_fn;
        memset(/* &init_fn */, 0, 0 /* sizeof(init_fn) */);
        init_fn_name = "__init";
        init_fn_name_len = 6;
        init_fn_param_count = 0;
        chunk_init(/* &init_fn_chunk */);
        var fi: i32 = module_add_function(/* &c_module */, init_fn);
        var ctx: i32 = 0;
        memset(/* &ctx */, 0, 0 /* sizeof(ctx) */);
        ctx_compiler = c;
        ctx_chunk = /* &array_get(c_module_functions, fi)_chunk */;
        ctx_scope_depth = 0;
        ctx_func_index = fi;
        var i: i32 = 0;
        while (i < prog_decl_count) {
            if (array_get(prog_decls, i)_kind == DECL_VAR) {
                var d: string = array_get(prog_decls, i);
                if d_gv_init {
                    gen_expr(/* &ctx */, d_gv_init);
                } else {
                    emit(/* &ctx */, OP_NIL, d_line);
                }
                var ni: i32 = module_find_name(/* &c_module */, d_gv_name, d_gv_name_len);
                emit(/* &ctx */, OP_GLOBAL_SET, d_line);
                emit_u16(/* &ctx */, ni, d_line);
                emit(/* &ctx */, OP_POP, d_line);
            }
            i = i + 1;
        }
        emit(/* &ctx */, OP_NIL, 0);
        emit(/* &ctx */, OP_RETURN, 0);
        array_get(c_module_functions, fi)_local_count = ctx_max_local_count;
    }
    return 0;
}

fn compiler_had_error(c: string) -> i32 {
    return c_had_error;
}

fn compiler_error(c: string) -> string {
    return c_error_msg;
}


// ════════════════════════════════════════════════
// Source: m/bootstrap/vm.c
// ════════════════════════════════════════════════

// Auto-translated from C by Machine
// Phase 2: M reads C, writes M

fn vm_set_error(vm: string, fmt: string, arg2: i32) -> i32;
fn vm_output(vm: string, fmt: string, arg2: i32) -> i32;

fn push(vm: string, v: i32) -> i32 {
    if (vm_stack_top >= VM_STACK_MAX) {
        vm_set_error(vm, "stack overflow");
        return 0;
    }
    array_get(vm_stack, vm_stack_top = vm_stack_top + 1) = v;
}

fn pop(vm: string) -> i32 {
    if (vm_stack_top <= 0) {
        vm_set_error(vm, "stack underflow");
        var v: i32 = 0;
        v_type = VAL_VOID;
        return v;
    }
    return array_get(vm_stack, /* --pre */ vm_stack_top);
}

fn peek(vm: string, distance: i32) -> i32 {
    return array_get(vm_stack, ((vm_stack_top - 1) - distance));
}

fn read_byte(frame: string) -> i32 {
    return /* *frame_ip = frame_ip + 1 */;
}

fn read_u16(frame: string) -> i32 {
    var hi: i32 = /* *frame_ip = frame_ip + 1 */;
    var lo: i32 = /* *frame_ip = frame_ip + 1 */;
    return ((hi << 8) | lo);
}

fn read_i16(frame: string) -> i32 {
    return read_u16(frame);
}

fn make_int(v: i32) -> i32 {
    var val: i32 = 0;
    val_type = VAL_INT;
    val_i = v;
    return val;
}

fn make_float(v: i32) -> i32 {
    var val: i32 = 0;
    val_type = VAL_FLOAT;
    val_f = v;
    return val;
}

fn make_bool(v: i32) -> i32 {
    var val: i32 = 0;
    val_type = VAL_BOOL;
    val_b = v;
    return val;
}

fn make_void() -> i32 {
    var val: i32 = 0;
    val_type = VAL_VOID;
    return val;
}

fn to_number(v: i32) -> i32 {
    // switch (v_type) {
    // case VAL_INT:
        return v_i;
    // case VAL_FLOAT:
        return v_f;
    // case VAL_BOOL:
        return v_b;
    // default:
        return 0.0;
    // }
}

fn is_truthy(v: i32) -> i32 {
    // switch (v_type) {
    // case VAL_BOOL:
        return v_b;
    // case VAL_INT:
        return (v_i != 0);
    // case VAL_FLOAT:
        return (v_f != 0.0);
    // case VAL_VOID:
        return 0;
    // default:
        return 1;
    // }
}

fn run(vm: string) -> i32 {
    var frame: string = /* &array_get(vm_frames, (vm_frame_count - 1)) */;
    (Chunk * chunk) = /* &frame_function_chunk */;
    while true {
        if vm_had_error {
            return VM_ERROR;
        }
        var op: i32 = read_byte(frame);
        // switch (op) {
        // case OP_CONST_INT:
            var idx: i32 = read_u16(frame);
            push(vm, make_int(array_get(chunk_ints, idx)));
            // break;
        // case OP_CONST_FLOAT:
            var idx: i32 = read_u16(frame);
            push(vm, make_float(array_get(chunk_floats, idx)));
            // break;
        // case OP_CONST_STRING:
            var idx: i32 = read_u16(frame);
            var v: i32 = 0;
            v_type = VAL_STRING;
            v_s = array_get(chunk_strings, idx)_str;
            v_s_len = array_get(chunk_strings, idx)_len;
            push(vm, v);
            // break;
        // case OP_TRUE:
            push(vm, make_bool(1));
            // break;
        // case OP_FALSE:
            push(vm, make_bool(0));
            // break;
        // case OP_NIL:
            push(vm, make_void());
            // break;
        // case OP_POP:
            pop(vm);
            // break;
        // case OP_LOCAL_GET:
            var slot: i32 = read_u16(frame);
            push(vm, array_get(frame_slots, slot));
            // break;
        // case OP_LOCAL_SET:
            var slot: i32 = read_u16(frame);
            array_get(frame_slots, slot) = peek(vm, 0);
            // break;
        // case OP_GLOBAL_GET:
            var ni: i32 = read_u16(frame);
            if (ni < vm_module_global_count) {
                push(vm, array_get(vm_module_globals, ni));
            } else {
                push(vm, make_void());
            }
            // break;
        // case OP_GLOBAL_SET:
            var ni: i32 = read_u16(frame);
            while (ni >= vm_module_global_count) {
                if (vm_module_global_count >= vm_module_global_cap) {
                    var new_cap: i32 = 0;
                    if (vm_module_global_cap < 8) {
                        new_cap = 8;
                    } else {
                        new_cap = (vm_module_global_cap * 2);
                    }
                    var new_g: string = tohum_alloc((new_cap * 0 /* sizeof(Val) */));
                    if vm_module_globals {
                        memcpy(new_g, vm_module_globals, (vm_module_global_count * 0 /* sizeof(Val) */));
                        tohum_free(vm_module_globals, (vm_module_global_cap * 0 /* sizeof(Val) */));
                    }
                    vm_module_globals = new_g;
                    vm_module_global_cap = new_cap;
                }
                array_get(vm_module_globals, vm_module_global_count)_type = VAL_VOID;
                vm_module_global_count = vm_module_global_count + 1;
            }
            array_get(vm_module_globals, ni) = peek(vm, 0);
            // break;
        // case OP_ADD:
            var b: i32 = pop(vm);
            if ((a_type == VAL_INT) && (b_type == VAL_INT)) {
                push(vm, make_int((a_i + b_i)));
            } else {
                push(vm, make_float((to_number(a) + to_number(b))));
            }
            // break;
        // case OP_SUB:
            var b: i32 = pop(vm);
            if ((a_type == VAL_INT) && (b_type == VAL_INT)) {
                push(vm, make_int((a_i - b_i)));
            } else {
                push(vm, make_float((to_number(a) - to_number(b))));
            }
            // break;
        // case OP_MUL:
            var b: i32 = pop(vm);
            if ((a_type == VAL_INT) && (b_type == VAL_INT)) {
                push(vm, make_int((a_i * b_i)));
            } else {
                push(vm, make_float((to_number(a) * to_number(b))));
            }
            // break;
        // case OP_DIV:
            var b: i32 = pop(vm);
            if ((b_type == VAL_INT) && (b_i == 0)) {
                vm_set_error(vm, "division by zero");
                return VM_ERROR;
            }
            if ((a_type == VAL_INT) && (b_type == VAL_INT)) {
                push(vm, make_int((a_i / b_i)));
            } else {
                push(vm, make_float((to_number(a) / to_number(b))));
            }
            // break;
        // case OP_MOD:
            var b: i32 = pop(vm);
            if ((a_type == VAL_INT) && (b_type == VAL_INT)) {
                if (b_i == 0) {
                    vm_set_error(vm, "modulo by zero");
                    return VM_ERROR;
                }
                push(vm, make_int((a_i % b_i)));
            } else {
                vm_set_error(vm, "modulo requires integers");
                return VM_ERROR;
            }
            // break;
        // case OP_NEG:
            var a: i32 = pop(vm);
            if (a_type == VAL_INT) {
                push(vm, make_int((0 - a_i)));
            } else {
                push(vm, make_float((0 - to_number(a))));
            }
            // break;
        // case OP_EQ:
            var b: i32 = pop(vm);
            push(vm, make_bool((to_number(a) == to_number(b))));
            // break;
        // case OP_NEQ:
            var b: i32 = pop(vm);
            push(vm, make_bool((to_number(a) != to_number(b))));
            // break;
        // case OP_LT:
            var b: i32 = pop(vm);
            push(vm, make_bool((to_number(a) < to_number(b))));
            // break;
        // case OP_GT:
            var b: i32 = pop(vm);
            push(vm, make_bool((to_number(a) > to_number(b))));
            // break;
        // case OP_LTE:
            var b: i32 = pop(vm);
            push(vm, make_bool((to_number(a) <= to_number(b))));
            // break;
        // case OP_GTE:
            var b: i32 = pop(vm);
            push(vm, make_bool((to_number(a) >= to_number(b))));
            // break;
        // case OP_AND:
            var b: i32 = pop(vm);
            push(vm, make_bool((is_truthy(a) && is_truthy(b))));
            // break;
        // case OP_OR:
            var b: i32 = pop(vm);
            push(vm, make_bool((is_truthy(a) || is_truthy(b))));
            // break;
        // case OP_NOT:
            var a: i32 = pop(vm);
            push(vm, make_bool(!is_truthy(a)));
            // break;
        // case OP_JUMP:
            var offset: i32 = read_i16(frame);
            frame_ip = frame_ip + offset;
            // break;
        // case OP_JUMP_FALSE:
            var offset: i32 = read_i16(frame);
            var cond: i32 = pop(vm);
            if !is_truthy(cond) {
                frame_ip = frame_ip + offset;
            }
            // break;
        // case OP_CALL:
            var argc: i32 = read_u16(frame);
            var callee_val: i32 = array_get(vm_stack, ((vm_stack_top - 1) - argc));
            if (callee_val_type != VAL_INT) {
                vm_set_error(vm, "cannot call non-function");
                return VM_ERROR;
            }
            var func_idx: i32 = callee_val_i;
            if ((func_idx < 0) || (func_idx >= vm_module_func_count)) {
                vm_set_error(vm, "invalid function index %d", func_idx);
                return VM_ERROR;
            }
            (Function * target) = /* &array_get(vm_module_functions, func_idx) */;
            if (target_param_count != argc) {
                vm_set_error(vm, "expected %d args, got %d", target_param_count, argc);
                return VM_ERROR;
            }
            if (vm_frame_count >= VM_FRAMES_MAX) {
                vm_set_error(vm, "call stack overflow");
                return VM_ERROR;
            }
            var arg_start: string = /* &array_get(vm_stack, ((vm_stack_top - 1) - argc)) */;
            var i: i32 = 0;
            while (i < argc) {
                array_get(arg_start, i) = array_get(arg_start, (i + 1));
                i = i + 1;
            }
            vm_stack_top = vm_stack_top - 1;
            var new_frame: string = /* &array_get(vm_frames, vm_frame_count = vm_frame_count + 1) */;
            new_frame_function = target;
            new_frame_ip = target_chunk_code;
            new_frame_slots = /* &array_get(vm_stack, (vm_stack_top - argc)) */;
            frame = new_frame;
            chunk = /* &frame_function_chunk */;
            var extra_locals: i32 = (target_local_count - argc);
            var i: i32 = 0;
            while (i < extra_locals) {
                push(vm, make_void());
                i = i + 1;
            }
            // break;
        // case OP_RETURN:
            var result: i32 = pop(vm);
            vm_frame_count = vm_frame_count - 1;
            if (vm_frame_count == 0) {
                push(vm, result);
                return VM_OK;
            }
            vm_stack_top = (frame_slots - vm_stack);
            push(vm, result);
            frame = /* &array_get(vm_frames, (vm_frame_count - 1)) */;
            chunk = /* &frame_function_chunk */;
            // break;
        // case OP_STRUCT_NEW:
            read_u16(frame);
            var n_fields: i32 = read_u16(frame);
            n_fields;
            // break;
        // case OP_FIELD_GET:
            read_u16(frame);
            // break;
        // case OP_FIELD_SET:
            read_u16(frame);
            pop(vm);
            // break;
        // case OP_ALLOC:
        // case OP_FREE:
        // case OP_LOAD:
        // case OP_STORE:
            // break;
        // case OP_PRINT:
            var v: i32 = pop(vm);
            // switch (v_type) {
            // case VAL_INT:
                vm_output(vm, "%lld", v_i);
                // break;
            // case VAL_FLOAT:
                vm_output(vm, "%g", v_f);
                // break;
            // case VAL_BOOL:
                vm_output(vm, "%s", /* v_b ? "true" : "false" */);
                // break;
            // case VAL_STRING:
                vm_output(vm, "%.*s", v_s_len, v_s);
                // break;
            // case VAL_VOID:
                vm_output(vm, "void");
                // break;
            // default:
                vm_output(vm, "?");
                // break;
            // }
            // break;
        // case OP_BUILTIN_LEN:
            var v: i32 = pop(vm);
            if (v_type == VAL_STRING) {
                push(vm, make_int(v_s_len));
            } else {
                vm_set_error(vm, "len() requires a string");
                return VM_ERROR;
            }
            // break;
        // case OP_BUILTIN_CHAR_AT:
            var idx: i32 = pop(vm);
            var str: i32 = pop(vm);
            if (str_type != VAL_STRING) {
                vm_set_error(vm, "char_at() requires a string");
                return VM_ERROR;
            }
            if (idx_type != VAL_INT) {
                vm_set_error(vm, "char_at() index must be integer");
                return VM_ERROR;
            }
            if ((idx_i < 0) || (idx_i >= str_s_len)) {
                vm_set_error(vm, "char_at() index %lld out of bounds (len=%d)", idx_i, str_s_len);
                return VM_ERROR;
            }
            push(vm, make_int(array_get(str_s, idx_i)));
            // break;
        // case OP_BUILTIN_SUBSTR:
            var vlen: i32 = pop(vm);
            var vstart: i32 = pop(vm);
            var vstr: i32 = pop(vm);
            if (vstr_type != VAL_STRING) {
                vm_set_error(vm, "substr() requires a string");
                return VM_ERROR;
            }
            var start: i32 = vstart_i;
            var slen: i32 = vlen_i;
            if (start < 0) {
                start = 0;
            }
            if (start > vstr_s_len) {
                start = vstr_s_len;
            }
            if (slen < 0) {
                slen = 0;
            }
            if ((start + slen) > vstr_s_len) {
                slen = (vstr_s_len - start);
            }
            var buf: string = tohum_alloc((slen + 1));
            memcpy(buf, (vstr_s + start), slen);
            array_get(buf, slen) = 0 /* '\0' */;
            var result: i32 = 0;
            result_type = VAL_STRING;
            result_s = buf;
            result_s_len = slen;
            push(vm, result);
            // break;
        // case OP_BUILTIN_STR_CONCAT:
            var b: i32 = pop(vm);
            var a: i32 = pop(vm);
            if ((a_type != VAL_STRING) || (b_type != VAL_STRING)) {
                vm_set_error(vm, "str_concat() requires two strings");
                return VM_ERROR;
            }
            var total: i32 = (a_s_len + b_s_len);
            var buf: string = tohum_alloc((total + 1));
            memcpy(buf, a_s, a_s_len);
            memcpy((buf + a_s_len), b_s, b_s_len);
            array_get(buf, total) = 0 /* '\0' */;
            var result: i32 = 0;
            result_type = VAL_STRING;
            result_s = buf;
            result_s_len = total;
            push(vm, result);
            // break;
        // case OP_BUILTIN_INT_TO_STR:
            var v: i32 = pop(vm);
            var buf: i32 = 0;
            var n: i32 = snprintf(buf, 0 /* sizeof(buf) */, "%lld", v_i);
            var str: string = tohum_alloc((n + 1));
            memcpy(str, buf, (n + 1));
            var result: i32 = 0;
            result_type = VAL_STRING;
            result_s = str;
            result_s_len = n;
            push(vm, result);
            // break;
        // case OP_BUILTIN_STR_EQ:
            var b: i32 = pop(vm);
            var a: i32 = pop(vm);
            if ((a_type != VAL_STRING) || (b_type != VAL_STRING)) {
                push(vm, make_bool(0));
            } else {
                var eq: i32 = ((a_s_len == b_s_len) && ((a_s_len == 0) || (memcmp(a_s, b_s, a_s_len) == 0)));
                push(vm, make_bool(eq));
            }
            // break;
        // case OP_BUILTIN_READ_FILE:
            var path: i32 = pop(vm);
            if (path_type != VAL_STRING) {
                vm_set_error(vm, "read_file() requires a string path");
                return VM_ERROR;
            }
            var cpath: string = tohum_alloc((path_s_len + 1));
            memcpy(cpath, path_s, path_s_len);
            array_get(cpath, path_s_len) = 0 /* '\0' */;
            var f: string = fopen(cpath, "rb");
            if !f {
                vm_set_error(vm, "cannot open file: %s", cpath);
                tohum_free(cpath, (path_s_len + 1));
                return VM_ERROR;
            }
            fseek(f, 0, SEEK_END);
            var fsize: i32 = ftell(f);
            fseek(f, 0, SEEK_SET);
            var buf: string = tohum_alloc((fsize + 1));
            fread(buf, 1, fsize, f);
            array_get(buf, fsize) = 0 /* '\0' */;
            fclose(f);
            tohum_free(cpath, (path_s_len + 1));
            var result: i32 = 0;
            result_type = VAL_STRING;
            result_s = buf;
            result_s_len = fsize;
            push(vm, result);
            // break;
        // case OP_BUILTIN_CHAR_TO_STR:
            var v: i32 = pop(vm);
            var buf: string = tohum_alloc(2);
            array_get(buf, 0) = (v_i & 0xFF);
            array_get(buf, 1) = 0 /* '\0' */;
            var result: i32 = 0;
            result_type = VAL_STRING;
            result_s = buf;
            result_s_len = 1;
            push(vm, result);
            // break;
        // case OP_ARRAY_NEW:
            read_u16(frame);
            var size_val: i32 = pop(vm);
            var cap: i32 = size_val_i;
            if (cap < 8) {
                cap = 8;
            }
            (VMArray * arr) = tohum_alloc(0 /* sizeof(VMArray) */);
            arr_data = tohum_alloc((cap * 0 /* sizeof(Val) */));
            arr_len = 0;
            arr_cap = cap;
            var i: i32 = 0;
            while (i < cap) {
                array_get(arr_data, i)_type = VAL_VOID;
                array_get(arr_data, i)_i = 0;
                i = i + 1;
            }
            var v: i32 = 0;
            v_type = VAL_ARRAY;
            v_array = arr;
            push(vm, v);
            // break;
        // case OP_ARRAY_GET:
            var idx: i32 = pop(vm);
            var arr_val: i32 = pop(vm);
            if (arr_val_type != VAL_ARRAY) {
                vm_set_error(vm, "array_get: not an array");
                return VM_ERROR;
            }
            var i: i32 = idx_i;
            if ((i < 0) || (i >= arr_val_array_len)) {
                vm_set_error(vm, "array_get: index %d out of bounds (len=%d)", i, arr_val_array_len);
                return VM_ERROR;
            }
            push(vm, array_get(arr_val_array_data, i));
            // break;
        // case OP_ARRAY_SET:
            var val: i32 = pop(vm);
            var idx: i32 = pop(vm);
            var arr_val: i32 = pop(vm);
            if (arr_val_type != VAL_ARRAY) {
                vm_set_error(vm, "array_set: not an array");
                return VM_ERROR;
            }
            var i: i32 = idx_i;
            if ((i < 0) || (i >= arr_val_array_len)) {
                vm_set_error(vm, "array_set: index %d out of bounds (len=%d)", i, arr_val_array_len);
                return VM_ERROR;
            }
            array_get(arr_val_array_data, i) = val;
            // break;
        // case OP_ARRAY_LEN:
            var arr_val: i32 = pop(vm);
            if (arr_val_type != VAL_ARRAY) {
                push(vm, make_int(0));
            } else {
                push(vm, make_int(arr_val_array_len));
            }
            // break;
        // case OP_ARRAY_PUSH:
            var val: i32 = pop(vm);
            var arr_val: i32 = pop(vm);
            if (arr_val_type != VAL_ARRAY) {
                vm_set_error(vm, "array_push: not an array");
                return VM_ERROR;
            }
            (VMArray * arr) = arr_val_array;
            if (arr_len >= arr_cap) {
                var new_cap: i32 = (arr_cap * 2);
                var new_data: string = tohum_alloc((new_cap * 0 /* sizeof(Val) */));
                memcpy(new_data, arr_data, (arr_len * 0 /* sizeof(Val) */));
                arr_data = new_data;
                arr_cap = new_cap;
            }
            array_get(arr_data, arr_len = arr_len + 1) = val;
            // break;
        // case OP_HALT:
            return VM_HALT;
        // case OP_BUILTIN_ARGC:
            push(vm, make_int(vm_prog_argc));
            // break;
        // case OP_BUILTIN_ARGV:
            var idx: i32 = pop(vm);
            var n: i32 = idx_i;
            if ((n < 0) || (n >= vm_prog_argc)) {
                vm_set_error(vm, "argv(%d) out of bounds (argc=%d)", n, vm_prog_argc);
                return VM_ERROR;
            }
            var arg: string = array_get(vm_prog_argv, n);
            var result: i32 = 0;
            result_type = VAL_STRING;
            result_s = arg;
            result_s_len = strlen(arg);
            push(vm, result);
            // break;
        // case OP_BUILTIN_WRITE_FILE:
            var content: i32 = pop(vm);
            var path: i32 = pop(vm);
            if ((path_type != VAL_STRING) || (content_type != VAL_STRING)) {
                vm_set_error(vm, "write_file() requires string path and content");
                return VM_ERROR;
            }
            var cpath: string = tohum_alloc((path_s_len + 1));
            memcpy(cpath, path_s, path_s_len);
            array_get(cpath, path_s_len) = 0 /* '\0' */;
            var f: string = fopen(cpath, "wb");
            var ok: i32 = 0;
            if f {
                fwrite(content_s, 1, content_s_len, f);
                fclose(f);
                ok = 1;
            }
            tohum_free(cpath, (path_s_len + 1));
            push(vm, make_bool(ok));
            // break;
        // default:
            vm_set_error(vm, "unknown opcode: %d", op);
            return VM_ERROR;
        // }
    }
}

fn vm_init(vm: string, module: string) -> i32 {
    memset(vm, 0, 0 /* sizeof(VM) */);
    vm_module = module;
    vm_output_cap = 8192;
    vm_output = tohum_alloc(vm_output_cap);
}

fn find_func(vm: string, name: string, len: i32) -> i32 {
    var i: i32 = 0;
    while (i < vm_module_func_count) {
        if ((array_get(vm_module_functions, i)_name_len == len) && (memcmp(array_get(vm_module_functions, i)_name, name, len) == 0)) {
            return i;
        }
        i = i + 1;
    }
    return (0 - 1);
}

fn vm_call_func(vm: string, fi: i32) -> i32 {
    (Function * entry) = /* &array_get(vm_module_functions, fi) */;
    var frame: string = /* &array_get(vm_frames, vm_frame_count = vm_frame_count + 1) */;
    frame_function = entry;
    frame_ip = entry_chunk_code;
    frame_slots = /* &array_get(vm_stack, vm_stack_top) */;
    var i: i32 = 0;
    while (i < entry_local_count) {
        push(vm, make_void());
        i = i + 1;
    }
    return run(vm);
}

fn vm_run(vm: string, entry_name: string) -> i32 {
    var name_len: i32 = strlen(entry_name);
    var init_fi: i32 = find_func(vm, "__init", 6);
    if (init_fi >= 0) {
        var r: i32 = vm_call_func(vm, init_fi);
        if (r != VM_OK) {
            return r;
        }
        vm_stack_top = 0;
        vm_frame_count = 0;
    }
    var fi: i32 = find_func(vm, entry_name, name_len);
    if (fi < 0) {
        vm_had_error = 1;
        snprintf(vm_error_msg, 0 /* sizeof(vm -> error_msg) */, "function '%s' not found", entry_name);
        return VM_ERROR;
    }
    return vm_call_func(vm, fi);
}

fn vm_result(vm: string) -> i32 {
    if (vm_stack_top > 0) {
        return array_get(vm_stack, (vm_stack_top - 1));
    }
    return make_void();
}

fn vm_error(vm: string) -> string {
    return vm_error_msg;
}


// ════════════════════════════════════════════════
// Source: m/bootstrap/mc.c
// ════════════════════════════════════════════════

// Auto-translated from C by Machine
// Phase 2: M reads C, writes M

fn read_file(path: string) -> string {
    var f: string = fopen(path, "rb");
    if !f {
        fprintf(stderr, "mc: cannot open '%s'\n", path);
        return 0 /* NULL */;
    }
    fseek(f, 0, SEEK_END);
    var size: i32 = ftell(f);
    fseek(f, 0, SEEK_SET);
    var buf: string = malloc((size + 1));
    if !buf {
        fclose(f);
        fprintf(stderr, "mc: out of memory\n");
        return 0 /* NULL */;
    }
    fread(buf, 1, size, f);
    array_get(buf, size) = 0 /* '\0' */;
    fclose(f);
    return buf;
}

fn already_included(path: string) -> i32 {
    var i: i32 = 0;
    while (i < included_count) {
        if (strcmp(array_get(included_files, i), path) == 0) {
            return 1;
        }
        i = i + 1;
    }
    return 0;
}

fn get_dir(path: string, dir: string, dir_size: i32) -> i32 {
    var last_sep: string = 0 /* NULL */;
    var p: string = path;
    while /* *p */ {
        if ((/* *p */ == 47 /* '/' */) || (/* *p */ == 92 /* '\\' */)) {
            last_sep = p;
        }
        p = p + 1;
    }
    if last_sep {
        var len: i32 = ((last_sep - path) + 1);
        if (len >= dir_size) {
            len = (dir_size - 1);
        }
        memcpy(dir, path, len);
        array_get(dir, len) = 0 /* '\0' */;
    } else {
        array_get(dir, 0) = 0 /* '\0' */;
    }
}

fn resolve_uses(source: string, base_dir: string) -> string {
    var out_cap: i32 = ((strlen(source) * 2) + 4096);
    var out: string = malloc(out_cap);
    var out_len: i32 = 0;
    var p: string = source;
    while /* *p */ {
        var line_start: string = p;
        while ((/* *p */ == 32 /* ' ' */) || (/* *p */ == 9 /* '\t' */)) {
            p = p + 1;
        }
        if (strncmp(p, "use ", 4) == 0) {
            p = p + 4;
            while ((/* *p */ == 32 /* ' ' */) || (/* *p */ == 9 /* '\t' */)) {
                p = p + 1;
            }
            if (/* *p */ == 34 /* '"' */) {
                p = p + 1;
                var path_start: string = p;
                while (/* *p */ && (/* *p */ != 34 /* '"' */)) {
                    p = p + 1;
                }
                if (/* *p */ == 34 /* '"' */) {
                    var path_len: i32 = (p - path_start);
                    p = p + 1;
                    while ((/* *p */ == 32 /* ' ' */) || (/* *p */ == 9 /* '\t' */)) {
                        p = p + 1;
                    }
                    if (/* *p */ == 59 /* ';' */) {
                        p = p + 1;
                    }
                    if (/* *p */ == 13 /* '\r' */) {
                        p = p + 1;
                    }
                    if (/* *p */ == 10 /* '\n' */) {
                        p = p + 1;
                    }
                    var full_path: i32 = 0;
                    if ((path_len > 0) && (((array_get(path_start, 0) == 47 /* '/' */) || (array_get(path_start, 0) == 92 /* '\\' */)) || ((path_len > 1) && (array_get(path_start, 1) == 58 /* ':' */)))) {
                        snprintf(full_path, 0 /* sizeof(full_path) */, "%.*s", path_len, path_start);
                    } else {
                        snprintf(full_path, 0 /* sizeof(full_path) */, "%s%.*s", base_dir, path_len, path_start);
                    }
                    if !already_included(full_path) {
                        if (included_count < MAX_INCLUDES) {
                            array_get(included_files, included_count = included_count + 1) = strdup(full_path);
                        }
                        var inc_source: string = read_file(full_path);
                        if inc_source {
                            var inc_dir: i32 = 0;
                            get_dir(full_path, inc_dir, 0 /* sizeof(inc_dir) */);
                            var resolved: string = resolve_uses(inc_source, inc_dir);
                            free(inc_source);
                            var rlen: i32 = strlen(resolved);
                            while (((out_len + rlen) + 2) > out_cap) {
                                out_cap = out_cap * 2;
                                out = realloc(out, out_cap);
                            }
                            memcpy((out + out_len), resolved, rlen);
                            out_len = out_len + rlen;
                            if ((rlen > 0) && (array_get(resolved, (rlen - 1)) != 10 /* '\n' */)) {
                                array_get(out, out_len = out_len + 1) = 10 /* '\n' */;
                            }
                            free(resolved);
                        } else {
                            fprintf(stderr, "mc: warning: cannot open '%s'\n", full_path);
                        }
                    }
                    // continue;
                }
            }
        }
        p = line_start;
        while (/* *p */ && (/* *p */ != 10 /* '\n' */)) {
            if ((out_len + 2) > out_cap) {
                out_cap = out_cap * 2;
                out = realloc(out, out_cap);
            }
            array_get(out, out_len = out_len + 1) = /* *p = p + 1 */;
        }
        if (/* *p */ == 10 /* '\n' */) {
            array_get(out, out_len = out_len + 1) = /* *p = p + 1 */;
        }
    }
    array_get(out, out_len) = 0 /* '\0' */;
    return out;
}

fn main(argc: i32, argv: string) -> i32 {
    if (argc < 2) {
        fprintf(stderr, "usage: mc <file.m>\n");
        return 1;
    }
    var raw_source: string = read_file(array_get(argv, 1));
    if !raw_source {
        return 1;
    }
    var base_dir: i32 = 0;
    get_dir(array_get(argv, 1), base_dir, 0 /* sizeof(base_dir) */);
    var source: string = resolve_uses(raw_source, base_dir);
    free(raw_source);
    Parser;
    p;
    parser_init(/* &p */, source);
    (Program * prog) = parser_parse(/* &p */);
    if parser_had_error(/* &p */) {
        fprintf(stderr, "mc: parse error: %s\n", parser_error(/* &p */));
        free(source);
        return 1;
    }
    Compiler;
    c;
    compiler_init(/* &c */);
    if (compiler_compile(/* &c */, prog) != 0) {
        fprintf(stderr, "mc: compile error: %s\n", compiler_error(/* &c */));
        free(source);
        return 1;
    }
    VM;
    vm;
    vm_init(/* &vm */, compiler_module(/* &c */));
    vm_prog_argc = (argc - 1);
    vm_prog_argv = (argv + 1);
    VMResult;
    r = vm_run(/* &vm */, "main");
    if (vm_output_len > 0) {
        fwrite(vm_output, 1, vm_output_len, stdout);
    }
    if (r == VM_ERROR) {
        fprintf(stderr, "mc: runtime error: %s\n", vm_error(/* &vm */));
        free(source);
        return 1;
    }
    Val;
    result = vm_result(/* &vm */);
    var exit_code: i32 = 0;
    if (result_type == VAL_INT) {
        exit_code = result_i;
    }
    free(source);
    return exit_code;
}



// M AST Interpreter: tokenize → parse → walk AST → execute
// Proves the self-hosting pipeline end-to-end before bytecode
// Combines self_parse.m's frontend with a tree-walking backend

// ── Character classification ─────────────────────────

fn is_digit(c: i32) -> bool { return c >= 48 && c <= 57; }
fn is_alpha(c: i32) -> bool {
    if c >= 65 && c <= 90 { return true; }
    if c >= 97 && c <= 122 { return true; }
    return c == 95;
}
fn is_alnum(c: i32) -> bool { return is_alpha(c) || is_digit(c); }
fn is_space(c: i32) -> bool { return c == 32 || c == 10 || c == 13 || c == 9; }

// ── Token types ──────────────────────────────────────

fn TK_EOF() -> i32    { return 0; }
fn TK_IDENT() -> i32  { return 1; }
fn TK_NUM() -> i32    { return 2; }
fn TK_STR() -> i32    { return 3; }
fn TK_KW_FN() -> i32  { return 10; }
fn TK_KW_LET() -> i32 { return 11; }
fn TK_KW_VAR() -> i32 { return 12; }
fn TK_KW_IF() -> i32  { return 13; }
fn TK_KW_ELSE() -> i32 { return 14; }
fn TK_KW_WHILE() -> i32 { return 15; }
fn TK_KW_RETURN() -> i32 { return 16; }
fn TK_KW_TRUE() -> i32  { return 17; }
fn TK_KW_FALSE() -> i32 { return 18; }
fn TK_KW_STRUCT() -> i32 { return 19; }
fn TK_KW_I32() -> i32   { return 20; }
fn TK_KW_I64() -> i32   { return 21; }
fn TK_KW_F64() -> i32   { return 22; }
fn TK_KW_BOOL() -> i32  { return 23; }
fn TK_KW_STRING() -> i32 { return 24; }
fn TK_PLUS() -> i32   { return 30; }
fn TK_MINUS() -> i32  { return 31; }
fn TK_STAR() -> i32   { return 32; }
fn TK_SLASH() -> i32  { return 33; }
fn TK_EQ() -> i32     { return 34; }
fn TK_NEQ() -> i32    { return 35; }
fn TK_LT() -> i32     { return 36; }
fn TK_GT() -> i32     { return 37; }
fn TK_LTE() -> i32    { return 38; }
fn TK_GTE() -> i32    { return 39; }
fn TK_ASSIGN() -> i32 { return 40; }
fn TK_AND() -> i32    { return 41; }
fn TK_OR() -> i32     { return 42; }
fn TK_NOT() -> i32    { return 43; }
fn TK_ARROW() -> i32  { return 44; }
fn TK_LPAREN() -> i32  { return 50; }
fn TK_RPAREN() -> i32  { return 51; }
fn TK_LBRACE() -> i32  { return 52; }
fn TK_RBRACE() -> i32  { return 53; }
fn TK_COLON() -> i32   { return 54; }
fn TK_SEMI() -> i32    { return 55; }
fn TK_COMMA() -> i32   { return 56; }
fn TK_DOT() -> i32     { return 57; }
fn TK_MOD() -> i32     { return 58; }

// ── Lexer state ──────────────────────────────────────

var tok_types: i32 = 0;
var tok_vals: i32 = 0;
var tok_count: i32 = 0;
var tok_pos: i32 = 0;

fn classify_word(w: string) -> i32 {
    if str_eq(w, "fn")     { return TK_KW_FN(); }
    if str_eq(w, "let")    { return TK_KW_LET(); }
    if str_eq(w, "var")    { return TK_KW_VAR(); }
    if str_eq(w, "if")     { return TK_KW_IF(); }
    if str_eq(w, "else")   { return TK_KW_ELSE(); }
    if str_eq(w, "while")  { return TK_KW_WHILE(); }
    if str_eq(w, "return") { return TK_KW_RETURN(); }
    if str_eq(w, "true")   { return TK_KW_TRUE(); }
    if str_eq(w, "false")  { return TK_KW_FALSE(); }
    if str_eq(w, "struct") { return TK_KW_STRUCT(); }
    if str_eq(w, "i32")    { return TK_KW_I32(); }
    if str_eq(w, "i64")    { return TK_KW_I64(); }
    if str_eq(w, "f64")    { return TK_KW_F64(); }
    if str_eq(w, "bool")   { return TK_KW_BOOL(); }
    if str_eq(w, "string") { return TK_KW_STRING(); }
    return TK_IDENT();
}

fn tokenize(src: string) -> i32 {
    tok_types = array_new(0);
    tok_vals = array_new(0);
    var i: i32 = 0;

    while i < len(src) {
        let c: i32 = char_at(src, i);
        if is_space(c) {
            i = i + 1;
        } else if c == 47 && i + 1 < len(src) && char_at(src, i + 1) == 47 {
            while i < len(src) && char_at(src, i) != 10 { i = i + 1; }
        } else if c == 34 {
            var start: i32 = i + 1;
            i = i + 1;
            while i < len(src) && char_at(src, i) != 34 {
                if char_at(src, i) == 92 { i = i + 1; }
                i = i + 1;
            }
            array_push(tok_types, TK_STR());
            array_push(tok_vals, substr(src, start, i - start));
            if i < len(src) { i = i + 1; }
        } else if is_digit(c) {
            var start: i32 = i;
            while i < len(src) && is_digit(char_at(src, i)) { i = i + 1; }
            array_push(tok_types, TK_NUM());
            array_push(tok_vals, substr(src, start, i - start));
        } else if is_alpha(c) {
            var start: i32 = i;
            while i < len(src) && is_alnum(char_at(src, i)) { i = i + 1; }
            let word: string = substr(src, start, i - start);
            array_push(tok_types, classify_word(word));
            array_push(tok_vals, word);
        } else if c == 61 && i + 1 < len(src) && char_at(src, i + 1) == 61 {
            array_push(tok_types, TK_EQ()); array_push(tok_vals, "=="); i = i + 2;
        } else if c == 33 && i + 1 < len(src) && char_at(src, i + 1) == 61 {
            array_push(tok_types, TK_NEQ()); array_push(tok_vals, "!="); i = i + 2;
        } else if c == 60 && i + 1 < len(src) && char_at(src, i + 1) == 61 {
            array_push(tok_types, TK_LTE()); array_push(tok_vals, "<="); i = i + 2;
        } else if c == 62 && i + 1 < len(src) && char_at(src, i + 1) == 61 {
            array_push(tok_types, TK_GTE()); array_push(tok_vals, ">="); i = i + 2;
        } else if c == 45 && i + 1 < len(src) && char_at(src, i + 1) == 62 {
            array_push(tok_types, TK_ARROW()); array_push(tok_vals, "->"); i = i + 2;
        } else if c == 38 && i + 1 < len(src) && char_at(src, i + 1) == 38 {
            array_push(tok_types, TK_AND()); array_push(tok_vals, "&&"); i = i + 2;
        } else if c == 124 && i + 1 < len(src) && char_at(src, i + 1) == 124 {
            array_push(tok_types, TK_OR()); array_push(tok_vals, "||"); i = i + 2;
        } else if c == 43 { array_push(tok_types, TK_PLUS()); array_push(tok_vals, "+"); i = i + 1;
        } else if c == 45 { array_push(tok_types, TK_MINUS()); array_push(tok_vals, "-"); i = i + 1;
        } else if c == 42 { array_push(tok_types, TK_STAR()); array_push(tok_vals, "*"); i = i + 1;
        } else if c == 47 { array_push(tok_types, TK_SLASH()); array_push(tok_vals, "/"); i = i + 1;
        } else if c == 37 { array_push(tok_types, TK_MOD()); array_push(tok_vals, "%"); i = i + 1;
        } else if c == 33 { array_push(tok_types, TK_NOT()); array_push(tok_vals, "!"); i = i + 1;
        } else if c == 61 { array_push(tok_types, TK_ASSIGN()); array_push(tok_vals, "="); i = i + 1;
        } else if c == 60 { array_push(tok_types, TK_LT()); array_push(tok_vals, "<"); i = i + 1;
        } else if c == 62 { array_push(tok_types, TK_GT()); array_push(tok_vals, ">"); i = i + 1;
        } else if c == 40 { array_push(tok_types, TK_LPAREN()); array_push(tok_vals, "("); i = i + 1;
        } else if c == 41 { array_push(tok_types, TK_RPAREN()); array_push(tok_vals, ")"); i = i + 1;
        } else if c == 123 { array_push(tok_types, TK_LBRACE()); array_push(tok_vals, "{"); i = i + 1;
        } else if c == 125 { array_push(tok_types, TK_RBRACE()); array_push(tok_vals, "}"); i = i + 1;
        } else if c == 58 { array_push(tok_types, TK_COLON()); array_push(tok_vals, ":"); i = i + 1;
        } else if c == 59 { array_push(tok_types, TK_SEMI()); array_push(tok_vals, ";"); i = i + 1;
        } else if c == 44 { array_push(tok_types, TK_COMMA()); array_push(tok_vals, ","); i = i + 1;
        } else if c == 46 { array_push(tok_types, TK_DOT()); array_push(tok_vals, "."); i = i + 1;
        } else {
            i = i + 1;
        }
    }

    array_push(tok_types, TK_EOF());
    array_push(tok_vals, "");
    tok_count = array_len(tok_types);
    tok_pos = 0;
    return tok_count;
}

// ── Parser helpers ───────────────────────────────────

fn peek() -> i32 {
    if tok_pos < tok_count { return array_get(tok_types, tok_pos); }
    return TK_EOF();
}

fn peek_val() -> string {
    if tok_pos < tok_count { return array_get(tok_vals, tok_pos); }
    return "";
}

fn advance() -> i32 {
    let t: i32 = peek();
    tok_pos = tok_pos + 1;
    return t;
}

fn advance_val() -> string {
    let v: string = peek_val();
    tok_pos = tok_pos + 1;
    return v;
}

fn expect(t: i32, msg: string) -> i32 {
    if peek() == t { advance(); return 1; }
    print("PARSE ERROR: expected ");
    print(msg);
    print(" got '");
    print(peek_val());
    println("'");
    return 0;
}

fn match_tok(t: i32) -> bool {
    if peek() == t { advance(); return true; }
    return false;
}

// ── AST node types ───────────────────────────────────

fn NK_INT_LIT() -> i32   { return 1; }
fn NK_STR_LIT() -> i32   { return 2; }
fn NK_BOOL_LIT() -> i32  { return 3; }
fn NK_IDENT() -> i32     { return 4; }
fn NK_BINARY() -> i32    { return 5; }
fn NK_UNARY() -> i32     { return 6; }
fn NK_CALL() -> i32      { return 7; }
fn NK_LET() -> i32       { return 10; }
fn NK_ASSIGN() -> i32    { return 11; }
fn NK_RETURN() -> i32    { return 12; }
fn NK_IF() -> i32        { return 13; }
fn NK_WHILE() -> i32     { return 14; }
fn NK_BLOCK() -> i32     { return 15; }
fn NK_EXPR_STMT() -> i32 { return 16; }
fn NK_FN_DECL() -> i32   { return 20; }
fn NK_VAR_DECL() -> i32  { return 21; }
fn NK_PROGRAM() -> i32   { return 30; }

// ── AST storage (flat arrays) ────────────────────────

var node_kinds: i32 = 0;
var node_data: i32 = 0;
var node_extra: i32 = 0;
var node_extra2: i32 = 0;
var node_names: i32 = 0;
var node_count: i32 = 0;
var child_lists: i32 = 0;
var child_count: i32 = 0;

fn init_ast() -> i32 {
    node_kinds = array_new(0);
    node_data = array_new(0);
    node_extra = array_new(0);
    node_extra2 = array_new(0);
    node_names = array_new(0);
    child_lists = array_new(0);
    node_count = 0;
    child_count = 0;
    return 0;
}

fn new_node(kind: i32, data: i32, extra: i32, extra2: i32, name: string) -> i32 {
    let idx: i32 = node_count;
    array_push(node_kinds, kind);
    array_push(node_data, data);
    array_push(node_extra, extra);
    array_push(node_extra2, extra2);
    array_push(node_names, name);
    node_count = node_count + 1;
    return idx;
}

fn flush_children(temp: i32) -> i32 {
    let start: i32 = child_count;
    var i: i32 = 0;
    while i < array_len(temp) {
        array_push(child_lists, array_get(temp, i));
        child_count = child_count + 1;
        i = i + 1;
    }
    return start;
}

fn nk(idx: i32) -> i32  { return array_get(node_kinds, idx); }
fn nd(idx: i32) -> i32  { return array_get(node_data, idx); }
fn ne(idx: i32) -> i32  { return array_get(node_extra, idx); }
fn ne2(idx: i32) -> i32 { return array_get(node_extra2, idx); }
fn nn(idx: i32) -> string { return array_get(node_names, idx); }
fn child(start: i32, i: i32) -> i32 { return array_get(child_lists, start + i); }

// ── Expression parser ────────────────────────────────

fn parse_expr() -> i32;
fn parse_stmt() -> i32;

fn parse_primary() -> i32 {
    let t: i32 = peek();
    if t == TK_NUM()      { return new_node(NK_INT_LIT(), 0, 0, 0, advance_val()); }
    if t == TK_STR()      { return new_node(NK_STR_LIT(), 0, 0, 0, advance_val()); }
    if t == TK_KW_TRUE()  { advance(); return new_node(NK_BOOL_LIT(), 1, 0, 0, "true"); }
    if t == TK_KW_FALSE() { advance(); return new_node(NK_BOOL_LIT(), 0, 0, 0, "false"); }
    if t == TK_IDENT()    { return new_node(NK_IDENT(), 0, 0, 0, advance_val()); }
    if t == TK_LPAREN() {
        advance();
        let inner: i32 = parse_expr();
        expect(TK_RPAREN(), "')'");
        return inner;
    }
    advance();
    return new_node(NK_INT_LIT(), 0, 0, 0, "0");
}

fn parse_postfix() -> i32 {
    var node: i32 = parse_primary();
    while true {
        if peek() == TK_LPAREN() {
            advance();
            var args: i32 = array_new(0);
            while peek() != TK_RPAREN() && peek() != TK_EOF() {
                array_push(args, parse_expr());
                if peek() != TK_RPAREN() { expect(TK_COMMA(), "','"); }
            }
            expect(TK_RPAREN(), "')'");
            let start: i32 = flush_children(args);
            node = new_node(NK_CALL(), node, start, array_len(args), "");
        } else if peek() == TK_DOT() {
            advance();
            node = new_node(7, node, 0, 0, advance_val());
        } else {
            return node;
        }
    }
    return node;
}

fn parse_unary() -> i32 {
    if peek() == TK_MINUS() { advance(); return new_node(NK_UNARY(), parse_postfix(), 31, 0, "-"); }
    if peek() == TK_NOT()   { advance(); return new_node(NK_UNARY(), parse_postfix(), 43, 0, "!"); }
    return parse_postfix();
}

fn parse_factor() -> i32 {
    var left: i32 = parse_unary();
    while peek() == TK_STAR() || peek() == TK_SLASH() || peek() == TK_MOD() {
        let op: i32 = advance();
        let right: i32 = parse_unary();
        let name: string = "*";
        if op == TK_SLASH() { name = "/"; }
        if op == TK_MOD() { name = "%"; }
        left = new_node(NK_BINARY(), left, right, op, name);
    }
    return left;
}

fn parse_term() -> i32 {
    var left: i32 = parse_factor();
    while peek() == TK_PLUS() || peek() == TK_MINUS() {
        let op: i32 = advance();
        let right: i32 = parse_factor();
        let name: string = "+";
        if op == TK_MINUS() { name = "-"; }
        left = new_node(NK_BINARY(), left, right, op, name);
    }
    return left;
}

fn parse_comparison() -> i32 {
    var left: i32 = parse_term();
    while peek() == TK_LT() || peek() == TK_GT() || peek() == TK_LTE() || peek() == TK_GTE() {
        let op: i32 = advance();
        let right: i32 = parse_term();
        let name: string = "<";
        if op == TK_GT() { name = ">"; }
        if op == TK_LTE() { name = "<="; }
        if op == TK_GTE() { name = ">="; }
        left = new_node(NK_BINARY(), left, right, op, name);
    }
    return left;
}

fn parse_equality() -> i32 {
    var left: i32 = parse_comparison();
    while peek() == TK_EQ() || peek() == TK_NEQ() {
        let op: i32 = advance();
        let right: i32 = parse_comparison();
        let name: string = "==";
        if op == TK_NEQ() { name = "!="; }
        left = new_node(NK_BINARY(), left, right, op, name);
    }
    return left;
}

fn parse_and() -> i32 {
    var left: i32 = parse_equality();
    while peek() == TK_AND() {
        advance();
        left = new_node(NK_BINARY(), left, parse_equality(), TK_AND(), "&&");
    }
    return left;
}

fn parse_expr() -> i32 {
    var left: i32 = parse_and();
    while peek() == TK_OR() {
        advance();
        left = new_node(NK_BINARY(), left, parse_and(), TK_OR(), "||");
    }
    return left;
}

// ── Statement parser ─────────────────────────────────

fn parse_block() -> i32 {
    expect(TK_LBRACE(), "'{'");
    var stmts: i32 = array_new(0);
    while peek() != TK_RBRACE() && peek() != TK_EOF() {
        array_push(stmts, parse_stmt());
    }
    expect(TK_RBRACE(), "'}'");
    let start: i32 = flush_children(stmts);
    return new_node(NK_BLOCK(), start, array_len(stmts), 0, "");
}

fn parse_type() -> string {
    let t: i32 = peek();
    if t == TK_KW_I32()    { advance(); return "i32"; }
    if t == TK_KW_I64()    { advance(); return "i64"; }
    if t == TK_KW_F64()    { advance(); return "f64"; }
    if t == TK_KW_BOOL()   { advance(); return "bool"; }
    if t == TK_KW_STRING() { advance(); return "string"; }
    if t == TK_IDENT()     { return advance_val(); }
    return "unknown";
}

fn parse_stmt() -> i32 {
    if peek() == TK_KW_LET() || peek() == TK_KW_VAR() {
        let is_var: i32 = 0;
        if peek() == TK_KW_VAR() { is_var = 1; }
        advance();
        let name: string = advance_val();
        if match_tok(TK_COLON()) { parse_type(); }
        var init: i32 = 0 - 1;
        if match_tok(TK_ASSIGN()) { init = parse_expr(); }
        expect(TK_SEMI(), "';'");
        return new_node(NK_LET(), init, is_var, 0, name);
    }
    if peek() == TK_KW_RETURN() {
        advance();
        var val: i32 = 0 - 1;
        if peek() != TK_SEMI() { val = parse_expr(); }
        expect(TK_SEMI(), "';'");
        return new_node(NK_RETURN(), val, 0, 0, "");
    }
    if peek() == TK_KW_IF() {
        advance();
        let cond: i32 = parse_expr();
        let then_b: i32 = parse_block();
        var else_b: i32 = 0 - 1;
        if match_tok(TK_KW_ELSE()) {
            if peek() == TK_KW_IF() {
                else_b = parse_stmt();
            } else {
                else_b = parse_block();
            }
        }
        return new_node(NK_IF(), cond, then_b, else_b, "");
    }
    if peek() == TK_KW_WHILE() {
        advance();
        let cond: i32 = parse_expr();
        let body: i32 = parse_block();
        return new_node(NK_WHILE(), cond, body, 0, "");
    }
    if peek() == TK_LBRACE() { return parse_block(); }

    let expr: i32 = parse_expr();
    if match_tok(TK_ASSIGN()) {
        let val: i32 = parse_expr();
        expect(TK_SEMI(), "';'");
        return new_node(NK_ASSIGN(), expr, val, 0, "");
    }
    expect(TK_SEMI(), "';'");
    return new_node(NK_EXPR_STMT(), expr, 0, 0, "");
}

// ── Declaration parser ───────────────────────────────

fn parse_fn_decl() -> i32 {
    let name: string = advance_val();
    expect(TK_LPAREN(), "'('");
    var params: i32 = array_new(0);
    while peek() != TK_RPAREN() && peek() != TK_EOF() {
        let pname: string = advance_val();
        expect(TK_COLON(), "':'");
        parse_type();
        array_push(params, new_node(NK_LET(), 0 - 1, 0, 0, pname));
        if peek() != TK_RPAREN() { expect(TK_COMMA(), "','"); }
    }
    expect(TK_RPAREN(), "')'");
    if match_tok(TK_ARROW()) { parse_type(); }
    var body: i32 = 0 - 1;
    if peek() == TK_SEMI() { advance(); } else { body = parse_block(); }
    let ps: i32 = flush_children(params);
    return new_node(NK_FN_DECL(), body, ps, array_len(params), name);
}

fn parse_global_var() -> i32 {
    let name: string = advance_val();
    if match_tok(TK_COLON()) { parse_type(); }
    var init: i32 = 0 - 1;
    if match_tok(TK_ASSIGN()) { init = parse_expr(); }
    expect(TK_SEMI(), "';'");
    return new_node(NK_VAR_DECL(), init, 0, 0, name);
}

fn parse_program() -> i32 {
    var decls: i32 = array_new(0);
    while peek() != TK_EOF() {
        if peek() == TK_KW_FN() { advance(); array_push(decls, parse_fn_decl()); }
        else if peek() == TK_KW_VAR() { advance(); array_push(decls, parse_global_var()); }
        else { advance(); }
    }
    let start: i32 = flush_children(decls);
    return new_node(NK_PROGRAM(), start, array_len(decls), 0, "");
}

// ══════════════════════════════════════════════════════
// ── INTERPRETER (tree-walking evaluator) ─────────────
// ══════════════════════════════════════════════════════

// Value types for the interpreter
fn VT_INT() -> i32    { return 1; }
fn VT_BOOL() -> i32   { return 2; }
fn VT_STR() -> i32    { return 3; }
fn VT_VOID() -> i32   { return 4; }

// Interpreter result: parallel arrays (type, int_val, str_val)
var res_type: i32 = 0;
var res_ival: i32 = 0;
var res_sval: i32 = 0;

// Environment: variable name → value (scope stack)
var env_names: i32 = 0;
var env_types: i32 = 0;
var env_ivals: i32 = 0;
var env_svals: i32 = 0;
var env_depths: i32 = 0;
var env_count: i32 = 0;
var scope_depth: i32 = 0;

// Function table: fn_name → AST node index
var fn_names: i32 = 0;
var fn_nodes: i32 = 0;
var fn_count: i32 = 0;

// Return flag: set when 'return' is hit
var has_returned: i32 = 0;
var ret_type: i32 = 0;
var ret_ival: i32 = 0;
var ret_sval: i32 = 0;

// Output capture for testing
var output_buf: string = "";

fn init_interp() -> i32 {
    env_names = array_new(0);
    env_types = array_new(0);
    env_ivals = array_new(0);
    env_svals = array_new(0);
    env_depths = array_new(0);
    env_count = 0;
    scope_depth = 0;
    fn_names = array_new(0);
    fn_nodes = array_new(0);
    fn_count = 0;
    has_returned = 0;
    output_buf = "";
    return 0;
}

// ── Environment operations ───────────────────────────

fn env_push(name: string, vtype: i32, ival: i32, sval: string) -> i32 {
    if env_count < array_len(env_names) {
        // Reuse slot (after scope restore)
        array_set(env_names, env_count, name);
        array_set(env_types, env_count, vtype);
        array_set(env_ivals, env_count, ival);
        array_set(env_svals, env_count, sval);
        array_set(env_depths, env_count, scope_depth);
    } else {
        array_push(env_names, name);
        array_push(env_types, vtype);
        array_push(env_ivals, ival);
        array_push(env_svals, sval);
        array_push(env_depths, scope_depth);
    }
    env_count = env_count + 1;
    return env_count - 1;
}

fn env_lookup(name: string) -> i32 {
    // Search from top of stack (most recent first)
    var i: i32 = env_count - 1;
    while i >= 0 {
        if str_eq(array_get(env_names, i), name) { return i; }
        i = i - 1;
    }
    return 0 - 1;
}

fn env_set(idx: i32, vtype: i32, ival: i32, sval: string) -> i32 {
    array_set(env_types, idx, vtype);
    array_set(env_ivals, idx, ival);
    array_set(env_svals, idx, sval);
    return 0;
}

fn begin_scope() -> i32 {
    scope_depth = scope_depth + 1;
    return scope_depth;
}

fn end_scope() -> i32 {
    while env_count > 0 && array_get(env_depths, env_count - 1) == scope_depth {
        env_count = env_count - 1;
    }
    scope_depth = scope_depth - 1;
    return scope_depth;
}

// ── Function registry ────────────────────────────────

fn register_fn(name: string, node_idx: i32) -> i32 {
    array_push(fn_names, name);
    array_push(fn_nodes, node_idx);
    fn_count = fn_count + 1;
    return 0;
}

fn find_fn(name: string) -> i32 {
    var i: i32 = 0;
    while i < fn_count {
        if str_eq(array_get(fn_names, i), name) {
            return array_get(fn_nodes, i);
        }
        i = i + 1;
    }
    return 0 - 1;
}

// ── Interpreter core ─────────────────────────────────

// Result registers (avoid allocations)
var eval_type: i32 = 0;
var eval_ival: i32 = 0;
var eval_sval: string = "";

fn interp_expr(idx: i32) -> i32;
fn interp_stmt(idx: i32) -> i32;

fn interp_expr(idx: i32) -> i32 {
    if idx < 0 {
        eval_type = VT_VOID();
        eval_ival = 0;
        eval_sval = "";
        return 0;
    }

    let kind: i32 = nk(idx);

    if kind == NK_INT_LIT() {
        eval_type = VT_INT();
        // Parse number string to int
        let s: string = nn(idx);
        var val: i32 = 0;
        var j: i32 = 0;
        while j < len(s) {
            val = val * 10 + char_at(s, j) - 48;
            j = j + 1;
        }
        eval_ival = val;
        eval_sval = "";
        return 0;
    }

    if kind == NK_STR_LIT() {
        eval_type = VT_STR();
        eval_ival = 0;
        eval_sval = nn(idx);
        return 0;
    }

    if kind == NK_BOOL_LIT() {
        eval_type = VT_BOOL();
        eval_ival = nd(idx);
        eval_sval = "";
        return 0;
    }

    if kind == NK_IDENT() {
        let name: string = nn(idx);
        let ei: i32 = env_lookup(name);
        if ei >= 0 {
            eval_type = array_get(env_types, ei);
            eval_ival = array_get(env_ivals, ei);
            eval_sval = array_get(env_svals, ei);
        } else {
            eval_type = VT_VOID();
            eval_ival = 0;
            eval_sval = "";
        }
        return 0;
    }

    if kind == NK_UNARY() {
        interp_expr(nd(idx));
        let op: i32 = ne(idx);
        if op == 31 { eval_ival = 0 - eval_ival; }
        if op == 43 {
            if eval_ival == 0 { eval_ival = 1; } else { eval_ival = 0; }
            eval_type = VT_BOOL();
        }
        return 0;
    }

    if kind == NK_BINARY() {
        let op: i32 = ne2(idx);

        // Short-circuit && and ||
        if op == TK_AND() {
            interp_expr(nd(idx));
            if eval_ival == 0 { eval_type = VT_BOOL(); eval_ival = 0; return 0; }
            interp_expr(ne(idx));
            eval_type = VT_BOOL();
            return 0;
        }
        if op == TK_OR() {
            interp_expr(nd(idx));
            if eval_ival != 0 { eval_type = VT_BOOL(); eval_ival = 1; return 0; }
            interp_expr(ne(idx));
            eval_type = VT_BOOL();
            return 0;
        }

        interp_expr(nd(idx));
        let lt: i32 = eval_type;
        let li: i32 = eval_ival;
        let ls: string = eval_sval;
        interp_expr(ne(idx));
        let ri: i32 = eval_ival;

        if op == TK_PLUS()  { eval_type = VT_INT(); eval_ival = li + ri; }
        if op == TK_MINUS() { eval_type = VT_INT(); eval_ival = li - ri; }
        if op == TK_STAR()  { eval_type = VT_INT(); eval_ival = li * ri; }
        if op == TK_SLASH() { eval_type = VT_INT(); if ri != 0 { eval_ival = li / ri; } else { eval_ival = 0; } }
        if op == TK_MOD()   { eval_type = VT_INT(); if ri != 0 { eval_ival = li - (li / ri) * ri; } else { eval_ival = 0; } }
        if op == TK_EQ()  { eval_type = VT_BOOL(); if li == ri { eval_ival = 1; } else { eval_ival = 0; } }
        if op == TK_NEQ() { eval_type = VT_BOOL(); if li != ri { eval_ival = 1; } else { eval_ival = 0; } }
        if op == TK_LT()  { eval_type = VT_BOOL(); if li < ri  { eval_ival = 1; } else { eval_ival = 0; } }
        if op == TK_GT()  { eval_type = VT_BOOL(); if li > ri  { eval_ival = 1; } else { eval_ival = 0; } }
        if op == TK_LTE() { eval_type = VT_BOOL(); if li <= ri { eval_ival = 1; } else { eval_ival = 0; } }
        if op == TK_GTE() { eval_type = VT_BOOL(); if li >= ri { eval_ival = 1; } else { eval_ival = 0; } }
        return 0;
    }

    if kind == NK_CALL() {
        let callee_idx: i32 = nd(idx);
        let arg_start: i32 = ne(idx);
        let argc: i32 = ne2(idx);
        let callee_name: string = nn(callee_idx);

        // Built-in: print
        if str_eq(callee_name, "print") {
            if argc >= 1 {
                interp_expr(child(arg_start, 0));
                if eval_type == VT_INT() {
                    output_buf = str_concat(output_buf, int_to_str(eval_ival));
                } else if eval_type == VT_STR() {
                    output_buf = str_concat(output_buf, eval_sval);
                } else if eval_type == VT_BOOL() {
                    if eval_ival != 0 { output_buf = str_concat(output_buf, "true"); }
                    else { output_buf = str_concat(output_buf, "false"); }
                }
            }
            eval_type = VT_VOID();
            return 0;
        }

        // Built-in: println
        if str_eq(callee_name, "println") {
            if argc >= 1 {
                interp_expr(child(arg_start, 0));
                if eval_type == VT_INT() {
                    output_buf = str_concat(output_buf, int_to_str(eval_ival));
                } else if eval_type == VT_STR() {
                    output_buf = str_concat(output_buf, eval_sval);
                } else if eval_type == VT_BOOL() {
                    if eval_ival != 0 { output_buf = str_concat(output_buf, "true"); }
                    else { output_buf = str_concat(output_buf, "false"); }
                }
            }
            output_buf = str_concat(output_buf, "\n");
            eval_type = VT_VOID();
            return 0;
        }

        // User-defined function call
        let fn_node: i32 = find_fn(callee_name);
        if fn_node < 0 {
            eval_type = VT_VOID();
            return 0;
        }

        // Evaluate arguments
        var arg_vals_t: i32 = array_new(0);
        var arg_vals_i: i32 = array_new(0);
        var arg_vals_s: i32 = array_new(0);
        var ai: i32 = 0;
        while ai < argc {
            interp_expr(child(arg_start, ai));
            array_push(arg_vals_t, eval_type);
            array_push(arg_vals_i, eval_ival);
            array_push(arg_vals_s, eval_sval);
            ai = ai + 1;
        }

        // Set up new scope with parameters
        let body: i32 = nd(fn_node);
        let param_start: i32 = ne(fn_node);
        let param_count: i32 = ne2(fn_node);
        let saved_env_count: i32 = env_count;
        let saved_depth: i32 = scope_depth;

        begin_scope();
        var pi: i32 = 0;
        while pi < param_count && pi < argc {
            let pname: string = nn(child(param_start, pi));
            env_push(pname, array_get(arg_vals_t, pi), array_get(arg_vals_i, pi), array_get(arg_vals_s, pi));
            pi = pi + 1;
        }

        // Execute body
        let saved_ret: i32 = has_returned;
        has_returned = 0;
        if body >= 0 { interp_stmt(body); }

        // Capture return value
        if has_returned != 0 {
            eval_type = ret_type;
            eval_ival = ret_ival;
            eval_sval = ret_sval;
        } else {
            eval_type = VT_VOID();
            eval_ival = 0;
            eval_sval = "";
        }

        // Restore scope
        has_returned = saved_ret;
        env_count = saved_env_count;
        scope_depth = saved_depth;
        return 0;
    }

    eval_type = VT_VOID();
    return 0;
}

// ── Statement interpreter ────────────────────────────

fn interp_stmt(idx: i32) -> i32 {
    if idx < 0 { return 0; }
    if has_returned != 0 { return 0; }

    let kind: i32 = nk(idx);

    if kind == NK_BLOCK() {
        let start: i32 = nd(idx);
        let count: i32 = ne(idx);
        begin_scope();
        var i: i32 = 0;
        while i < count && has_returned == 0 {
            interp_stmt(child(start, i));
            i = i + 1;
        }
        end_scope();
        return 0;
    }

    if kind == NK_LET() {
        let name: string = nn(idx);
        let init: i32 = nd(idx);
        if init >= 0 {
            interp_expr(init);
            env_push(name, eval_type, eval_ival, eval_sval);
        } else {
            env_push(name, VT_INT(), 0, "");
        }
        return 0;
    }

    if kind == NK_ASSIGN() {
        let target: i32 = nd(idx);
        let val: i32 = ne(idx);
        let name: string = nn(target);
        interp_expr(val);
        let ei: i32 = env_lookup(name);
        if ei >= 0 {
            env_set(ei, eval_type, eval_ival, eval_sval);
        }
        return 0;
    }

    if kind == NK_RETURN() {
        let val: i32 = nd(idx);
        if val >= 0 {
            interp_expr(val);
            ret_type = eval_type;
            ret_ival = eval_ival;
            ret_sval = eval_sval;
        } else {
            ret_type = VT_VOID();
            ret_ival = 0;
            ret_sval = "";
        }
        has_returned = 1;
        return 0;
    }

    if kind == NK_IF() {
        let cond: i32 = nd(idx);
        let then_b: i32 = ne(idx);
        let else_b: i32 = ne2(idx);
        interp_expr(cond);
        if eval_ival != 0 {
            interp_stmt(then_b);
        } else if else_b >= 0 {
            interp_stmt(else_b);
        }
        return 0;
    }

    if kind == NK_WHILE() {
        let cond: i32 = nd(idx);
        let body: i32 = ne(idx);
        while has_returned == 0 {
            interp_expr(cond);
            if eval_ival == 0 { return 0; }
            interp_stmt(body);
        }
        return 0;
    }

    if kind == NK_EXPR_STMT() {
        interp_expr(nd(idx));
        return 0;
    }

    return 0;
}

// ── Program execution ────────────────────────────────

fn run_program(root: i32) -> i32 {
    let start: i32 = nd(root);
    let count: i32 = ne(root);

    // First pass: register all functions and init globals
    var i: i32 = 0;
    while i < count {
        let decl: i32 = child(start, i);
        let kind: i32 = nk(decl);
        if kind == NK_FN_DECL() {
            register_fn(nn(decl), decl);
        }
        if kind == NK_VAR_DECL() {
            let name: string = nn(decl);
            let init: i32 = nd(decl);
            if init >= 0 {
                interp_expr(init);
                env_push(name, eval_type, eval_ival, eval_sval);
            } else {
                env_push(name, VT_INT(), 0, "");
            }
        }
        i = i + 1;
    }

    // Call main()
    let main_node: i32 = find_fn("main");
    if main_node < 0 {
        output_buf = str_concat(output_buf, "ERROR: no main() found\n");
        return 0 - 1;
    }

    let body: i32 = nd(main_node);
    has_returned = 0;
    if body >= 0 { interp_stmt(body); }

    if has_returned != 0 { return ret_ival; }
    return 0;
}

// ══════════════════════════════════════════════════════
// ── TESTS ────────────────────────────────────────────
// ══════════════════════════════════════════════════════

var tests_passed: i32 = 0;
var tests_run: i32 = 0;

fn run_test(src: string, expected_ret: i32, expected_out: string, label: string) -> i32 {
    tests_run = tests_run + 1;
    init_ast();
    init_interp();
    tokenize(src);
    let root: i32 = parse_program();
    let ret: i32 = run_program(root);

    var ok: i32 = 1;
    if ret != expected_ret { ok = 0; }
    if len(expected_out) > 0 && !str_eq(output_buf, expected_out) { ok = 0; }

    if ok == 1 {
        tests_passed = tests_passed + 1;
        print("  OK  ");
    } else {
        print("  FAIL ");
        print("ret=");
        print(ret);
        print(" expected=");
        print(expected_ret);
        if len(expected_out) > 0 {
            print(" out='");
            print(output_buf);
            print("' expected='");
            print(expected_out);
            print("'");
        }
        print("  ");
    }
    println(label);
    return ok;
}

fn main() -> i32 {
    println("=== M AST Interpreter ===");
    println("tokenize -> parse -> walk AST -> execute");
    println("");

    // Basic returns
    run_test("fn main() -> i32 { return 42; }", 42, "", "return 42");
    run_test("fn main() -> i32 { return 0; }", 0, "", "return 0");

    // Arithmetic
    run_test("fn main() -> i32 { return 2 + 3; }", 5, "", "2 + 3");
    run_test("fn main() -> i32 { return 10 - 4; }", 6, "", "10 - 4");
    run_test("fn main() -> i32 { return 3 * 7; }", 21, "", "3 * 7");
    run_test("fn main() -> i32 { return 20 / 4; }", 5, "", "20 / 4");
    run_test("fn main() -> i32 { return 2 + 3 * 4; }", 14, "", "precedence: 2+3*4");
    run_test("fn main() -> i32 { return (2 + 3) * 4; }", 20, "", "parens: (2+3)*4");

    // Variables
    run_test("fn main() -> i32 { let x: i32 = 10; return x; }", 10, "", "let x = 10");
    run_test("fn main() -> i32 { var x: i32 = 5; x = x + 1; return x; }", 6, "", "var mutation");

    // If/else
    run_test("fn main() -> i32 { if 1 == 1 { return 10; } return 20; }", 10, "", "if true");
    run_test("fn main() -> i32 { if 1 == 2 { return 10; } return 20; }", 20, "", "if false");
    run_test("fn main() -> i32 { if 1 > 2 { return 1; } else { return 2; } }", 2, "", "if/else");

    // While
    run_test("fn main() -> i32 { var i: i32 = 0; while i < 10 { i = i + 1; } return i; }", 10, "", "while loop");

    // Functions
    run_test("fn add(a: i32, b: i32) -> i32 { return a + b; } fn main() -> i32 { return add(3, 4); }", 7, "", "fn call");
    run_test("fn fib(n: i32) -> i32 { if n <= 1 { return n; } return fib(n - 1) + fib(n - 2); } fn main() -> i32 { return fib(10); }", 55, "", "fibonacci(10)");

    // Forward calls
    run_test("fn a() -> i32 { return b(); } fn b() -> i32 { return 99; } fn main() -> i32 { return a(); }", 99, "", "forward call");

    // Global variables
    run_test("var g: i32 = 0; fn inc() -> i32 { g = g + 1; return g; } fn main() -> i32 { inc(); inc(); inc(); return g; }", 3, "", "global var");

    // Boolean logic
    run_test("fn main() -> i32 { if true && true { return 1; } return 0; }", 1, "", "&& true");
    run_test("fn main() -> i32 { if true && false { return 1; } return 0; }", 0, "", "&& false");
    run_test("fn main() -> i32 { if false || true { return 1; } return 0; }", 1, "", "|| true");

    // Print output
    run_test("fn main() -> i32 { print(42); return 0; }", 0, "42", "print int");
    run_test("fn main() -> i32 { println(\"hello\"); return 0; }", 0, "hello\n", "println str");

    // Comparison
    run_test("fn main() -> i32 { if 5 >= 5 { return 1; } return 0; }", 1, "", ">=");
    run_test("fn main() -> i32 { if 3 != 4 { return 1; } return 0; }", 1, "", "!=");

    // Negation
    run_test("fn main() -> i32 { return 0 - 42; }", 0 - 42, "", "negation");

    // Nested function calls
    run_test("fn double(x: i32) -> i32 { return x * 2; } fn main() -> i32 { return double(double(5)); }", 20, "", "nested calls");

    println("");
    print(tests_passed);
    print("/");
    print(tests_run);
    println(" tests passed");

    if tests_passed == tests_run {
        println("");
        println("M interprets M. The language lives.");
    }

    return 0;
}

// M lexer that collects tokens into arrays
// Next step toward self-hosting: structured token output

fn is_digit(c: i32) -> bool { return c >= 48 && c <= 57; }
fn is_alpha(c: i32) -> bool {
    if c >= 65 && c <= 90 { return true; }
    if c >= 97 && c <= 122 { return true; }
    return c == 95;
}
fn is_alnum(c: i32) -> bool { return is_alpha(c) || is_digit(c); }
fn is_space(c: i32) -> bool { return c == 32 || c == 10 || c == 13 || c == 9; }

// Token types
fn TK_KW() -> i32 { return 1; }
fn TK_ID() -> i32 { return 2; }
fn TK_NUM() -> i32 { return 3; }
fn TK_STR() -> i32 { return 4; }
fn TK_OP() -> i32 { return 5; }

fn is_keyword(word: string) -> bool {
    if str_eq(word, "fn") { return true; }
    if str_eq(word, "let") { return true; }
    if str_eq(word, "var") { return true; }
    if str_eq(word, "if") { return true; }
    if str_eq(word, "else") { return true; }
    if str_eq(word, "while") { return true; }
    if str_eq(word, "return") { return true; }
    if str_eq(word, "true") { return true; }
    if str_eq(word, "false") { return true; }
    if str_eq(word, "struct") { return true; }
    if str_eq(word, "i32") { return true; }
    if str_eq(word, "i64") { return true; }
    if str_eq(word, "f64") { return true; }
    if str_eq(word, "bool") { return true; }
    if str_eq(word, "string") { return true; }
    return false;
}

fn type_name(t: i32) -> string {
    if t == 1 { return "KW   "; }
    if t == 2 { return "IDENT"; }
    if t == 3 { return "NUM  "; }
    if t == 4 { return "STR  "; }
    return "OP   ";
}

fn lex(src: string) -> i32 {
    // Two parallel arrays: types and values
    var types: i32 = array_new(0);
    var values: i32 = array_new(0);
    var pos: i32 = 0;

    while pos < len(src) {
        let c: i32 = char_at(src, pos);

        if is_space(c) {
            pos = pos + 1;
        } else if c == 47 && pos + 1 < len(src) && char_at(src, pos + 1) == 47 {
            while pos < len(src) && char_at(src, pos) != 10 { pos = pos + 1; }
        } else if c == 34 {
            var start: i32 = pos;
            pos = pos + 1;
            while pos < len(src) && char_at(src, pos) != 34 {
                if char_at(src, pos) == 92 { pos = pos + 1; }
                pos = pos + 1;
            }
            if pos < len(src) { pos = pos + 1; }
            array_push(types, TK_STR());
            array_push(values, substr(src, start, pos - start));
        } else if is_digit(c) {
            var start: i32 = pos;
            while pos < len(src) && is_digit(char_at(src, pos)) { pos = pos + 1; }
            array_push(types, TK_NUM());
            array_push(values, substr(src, start, pos - start));
        } else if is_alpha(c) {
            var start: i32 = pos;
            while pos < len(src) && is_alnum(char_at(src, pos)) { pos = pos + 1; }
            let word: string = substr(src, start, pos - start);
            if is_keyword(word) {
                array_push(types, TK_KW());
            } else {
                array_push(types, TK_ID());
            }
            array_push(values, word);
        } else {
            var consumed: i32 = 1;
            if pos + 1 < len(src) {
                let c2: i32 = char_at(src, pos + 1);
                if c == 61 && c2 == 61 { consumed = 2; }
                if c == 33 && c2 == 61 { consumed = 2; }
                if c == 60 && c2 == 61 { consumed = 2; }
                if c == 62 && c2 == 61 { consumed = 2; }
                if c == 45 && c2 == 62 { consumed = 2; }
                if c == 38 && c2 == 38 { consumed = 2; }
                if c == 124 && c2 == 124 { consumed = 2; }
            }
            array_push(types, TK_OP());
            array_push(values, substr(src, pos, consumed));
            pos = pos + consumed;
        }
    }

    // Print all collected tokens
    var i: i32 = 0;
    while i < array_len(types) {
        let t: i32 = array_get(types, i);
        let v: string = array_get(values, i);
        print(int_to_str(i));
        print(": ");
        print(type_name(t));
        print("  ");
        println(v);
        i = i + 1;
    }

    return array_len(types);
}

fn main() -> i32 {
    println("=== M Lexer with Token Collection ===");
    println("");
    let src: string = "fn main() -> i32 { let x: i32 = 42; return x + 1; }";
    let count: i32 = lex(src);
    println("");
    print("Collected ");
    print(count);
    println(" tokens into arrays");
    return 0;
}

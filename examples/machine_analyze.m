// Machine Analyze — M source code analyzer for temporal VM
// Phase C: Machine reads and understands code.
//
// Reads M source files, extracts structure (functions, calls),
// and populates the temporal VM with program knowledge.
//
// Usage (from REPL):
//   analyze examples/self_codegen.m
//   funcs
//   calls vm_exec

// ── Analysis storage ─────────────────────────────────
// Functions found in analyzed file

var ana_file: string = "";        // current file path
var ana_source: string = "";      // raw source text
var ana_src_lines: i32 = 0;       // total source lines

// Function table (parallel arrays)
var ana_fn_names: i32 = 0;        // string pool indices
var ana_fn_params: i32 = 0;       // param count per function
var ana_fn_start: i32 = 0;        // start line number
var ana_fn_end: i32 = 0;          // end line number
var ana_fn_body_calls: i32 = 0;   // array of arrays: call target names (sp indices)
var ana_fn_count: i32 = 0;

// Global variable table
var ana_gv_names: i32 = 0;        // string pool indices
var ana_gv_types: i32 = 0;        // string pool indices (type name)
var ana_gv_count: i32 = 0;

// Use directive table
var ana_use_paths: i32 = 0;       // string pool indices
var ana_use_count: i32 = 0;

fn ana_init() {
    ana_fn_names = array_new(0);
    ana_fn_params = array_new(0);
    ana_fn_start = array_new(0);
    ana_fn_end = array_new(0);
    ana_fn_body_calls = array_new(0);
    ana_fn_count = 0;

    ana_gv_names = array_new(0);
    ana_gv_types = array_new(0);
    ana_gv_count = 0;

    ana_use_paths = array_new(0);
    ana_use_count = 0;

    ana_file = "";
    ana_source = "";
    ana_src_lines = 0;
}

// ── Tokenizer (minimal, for structure extraction) ────
// We only need to identify: fn, var, use, identifiers, braces, parens, strings, comments

fn ANA_TK_FN() -> i32     { return 1; }
fn ANA_TK_VAR() -> i32    { return 2; }
fn ANA_TK_USE() -> i32    { return 3; }
fn ANA_TK_IDENT() -> i32  { return 4; }
fn ANA_TK_LBRACE() -> i32 { return 5; }
fn ANA_TK_RBRACE() -> i32 { return 6; }
fn ANA_TK_LPAREN() -> i32 { return 7; }
fn ANA_TK_RPAREN() -> i32 { return 8; }
fn ANA_TK_COMMA() -> i32  { return 9; }
fn ANA_TK_COLON() -> i32  { return 10; }
fn ANA_TK_ARROW() -> i32  { return 11; }  // ->
fn ANA_TK_STR() -> i32    { return 12; }
fn ANA_TK_OTHER() -> i32  { return 13; }
fn ANA_TK_EOF() -> i32    { return 14; }

var tk_types: i32 = 0;
var tk_svals: i32 = 0;     // string pool indices for identifiers/strings
var tk_lines: i32 = 0;     // line number of each token
var tk_count: i32 = 0;

fn ana_is_alpha(c: i32) -> bool {
    if c >= 65 && c <= 90 { return true; }
    if c >= 97 && c <= 122 { return true; }
    return c == 95;
}

fn ana_is_digit(c: i32) -> bool { return c >= 48 && c <= 57; }

fn ana_tokenize(src: string) -> i32 {
    tk_types = array_new(0);
    tk_svals = array_new(0);
    tk_lines = array_new(0);
    tk_count = 0;

    var pos: i32 = 0;
    var line: i32 = 1;
    let slen: i32 = len(src);

    while pos < slen {
        let c: i32 = char_at(src, pos);

        // Newline
        if c == 10 {
            line = line + 1;
            pos = pos + 1;
        }
        // Whitespace
        else if c == 32 || c == 9 || c == 13 {
            pos = pos + 1;
        }
        // Line comment: //
        else if c == 47 && pos + 1 < slen && char_at(src, pos + 1) == 47 {
            while pos < slen && char_at(src, pos) != 10 {
                pos = pos + 1;
            }
        }
        // String literal
        else if c == 34 {
            pos = pos + 1;
            var start: i32 = pos;
            while pos < slen && char_at(src, pos) != 34 {
                if char_at(src, pos) == 92 { pos = pos + 1; }  // skip escape
                pos = pos + 1;
            }
            let s: string = substr(src, start, pos - start);
            if pos < slen { pos = pos + 1; }
            array_push(tk_types, ANA_TK_STR());
            array_push(tk_svals, sp_store(s));
            array_push(tk_lines, line);
            tk_count = tk_count + 1;
        }
        // Identifier or keyword
        else if ana_is_alpha(c) {
            var start: i32 = pos;
            while pos < slen && (ana_is_alpha(char_at(src, pos)) || ana_is_digit(char_at(src, pos))) {
                pos = pos + 1;
            }
            let word: string = substr(src, start, pos - start);
            var ttype: i32 = ANA_TK_IDENT();
            if str_eq(word, "fn") { ttype = ANA_TK_FN(); }
            else if str_eq(word, "var") { ttype = ANA_TK_VAR(); }
            else if str_eq(word, "use") { ttype = ANA_TK_USE(); }
            array_push(tk_types, ttype);
            array_push(tk_svals, sp_store(word));
            array_push(tk_lines, line);
            tk_count = tk_count + 1;
        }
        // Arrow: ->
        else if c == 45 && pos + 1 < slen && char_at(src, pos + 1) == 62 {
            array_push(tk_types, ANA_TK_ARROW());
            array_push(tk_svals, 0);
            array_push(tk_lines, line);
            tk_count = tk_count + 1;
            pos = pos + 2;
        }
        // Single-char tokens
        else if c == 123 {
            array_push(tk_types, ANA_TK_LBRACE());
            array_push(tk_svals, 0);
            array_push(tk_lines, line);
            tk_count = tk_count + 1;
            pos = pos + 1;
        }
        else if c == 125 {
            array_push(tk_types, ANA_TK_RBRACE());
            array_push(tk_svals, 0);
            array_push(tk_lines, line);
            tk_count = tk_count + 1;
            pos = pos + 1;
        }
        else if c == 40 {
            array_push(tk_types, ANA_TK_LPAREN());
            array_push(tk_svals, 0);
            array_push(tk_lines, line);
            tk_count = tk_count + 1;
            pos = pos + 1;
        }
        else if c == 41 {
            array_push(tk_types, ANA_TK_RPAREN());
            array_push(tk_svals, 0);
            array_push(tk_lines, line);
            tk_count = tk_count + 1;
            pos = pos + 1;
        }
        else if c == 44 {
            array_push(tk_types, ANA_TK_COMMA());
            array_push(tk_svals, 0);
            array_push(tk_lines, line);
            tk_count = tk_count + 1;
            pos = pos + 1;
        }
        else if c == 58 {
            array_push(tk_types, ANA_TK_COLON());
            array_push(tk_svals, 0);
            array_push(tk_lines, line);
            tk_count = tk_count + 1;
            pos = pos + 1;
        }
        else {
            // Skip anything else (numbers, operators, etc.)
            pos = pos + 1;
        }
    }

    // EOF token
    array_push(tk_types, ANA_TK_EOF());
    array_push(tk_svals, 0);
    array_push(tk_lines, line);
    tk_count = tk_count + 1;

    ana_src_lines = line;
    return tk_count;
}

// ── Structure extraction ─────────────────────────────

fn ana_tk_type(i: i32) -> i32 { return array_get(tk_types, i); }
fn ana_tk_sval(i: i32) -> string { return sp_get(array_get(tk_svals, i)); }
fn ana_tk_line(i: i32) -> i32 { return array_get(tk_lines, i); }

fn ana_extract_structure() {
    var i: i32 = 0;

    while i < tk_count {
        let tt: i32 = ana_tk_type(i);

        // use "path"
        if tt == ANA_TK_USE() && i + 1 < tk_count && ana_tk_type(i + 1) == ANA_TK_STR() {
            let path: string = ana_tk_sval(i + 1);
            array_push(ana_use_paths, sp_store(path));
            ana_use_count = ana_use_count + 1;
            i = i + 2;
        }

        // var name: type
        else if tt == ANA_TK_VAR() && i + 1 < tk_count && ana_tk_type(i + 1) == ANA_TK_IDENT() {
            let name: string = ana_tk_sval(i + 1);
            var typename: string = "unknown";
            // Look for : type pattern
            if i + 2 < tk_count && ana_tk_type(i + 2) == ANA_TK_COLON() {
                if i + 3 < tk_count && ana_tk_type(i + 3) == ANA_TK_IDENT() {
                    typename = ana_tk_sval(i + 3);
                }
            }
            array_push(ana_gv_names, sp_store(name));
            array_push(ana_gv_types, sp_store(typename));
            ana_gv_count = ana_gv_count + 1;
            i = i + 2;
        }

        // fn name(params) -> type { body }
        else if tt == ANA_TK_FN() && i + 1 < tk_count && ana_tk_type(i + 1) == ANA_TK_IDENT() {
            let fname: string = ana_tk_sval(i + 1);
            let start_line: i32 = ana_tk_line(i);

            // Count parameters
            var param_count: i32 = 0;
            var j: i32 = i + 2;

            // Skip to (
            while j < tk_count && ana_tk_type(j) != ANA_TK_LPAREN() && ana_tk_type(j) != ANA_TK_LBRACE() {
                j = j + 1;
            }

            if j < tk_count && ana_tk_type(j) == ANA_TK_LPAREN() {
                j = j + 1;
                // Count params by looking for identifiers before colons
                var in_params: bool = true;
                while j < tk_count && in_params {
                    if ana_tk_type(j) == ANA_TK_RPAREN() {
                        in_params = false;
                    } else if ana_tk_type(j) == ANA_TK_IDENT() && j + 1 < tk_count && ana_tk_type(j + 1) == ANA_TK_COLON() {
                        param_count = param_count + 1;
                        j = j + 1;
                    } else {
                        j = j + 1;
                    }
                }
            }

            // Find opening brace
            while j < tk_count && ana_tk_type(j) != ANA_TK_LBRACE() {
                j = j + 1;
            }

            // Match braces to find function end, collect calls
            var calls: i32 = array_new(0);
            var call_set: i32 = array_new(0);  // dedup: sp indices of already-added calls
            var call_set_n: i32 = 0;
            var depth: i32 = 0;
            if j < tk_count && ana_tk_type(j) == ANA_TK_LBRACE() {
                depth = 1;
                j = j + 1;
                while j < tk_count && depth > 0 {
                    let bt: i32 = ana_tk_type(j);
                    if bt == ANA_TK_LBRACE() {
                        depth = depth + 1;
                    } else if bt == ANA_TK_RBRACE() {
                        depth = depth - 1;
                    }
                    // Detect function calls: IDENT followed by LPAREN
                    else if bt == ANA_TK_IDENT() && j + 1 < tk_count && ana_tk_type(j + 1) == ANA_TK_LPAREN() {
                        let call_name: string = ana_tk_sval(j);
                        let call_si: i32 = sp_store(call_name);
                        // Dedup check
                        var found: bool = false;
                        var k: i32 = 0;
                        while k < call_set_n {
                            if str_eq(sp_get(array_get(call_set, k)), call_name) {
                                found = true;
                            }
                            k = k + 1;
                        }
                        if !found {
                            array_push(calls, call_si);
                            array_push(call_set, call_si);
                            call_set_n = call_set_n + 1;
                        }
                    }
                    j = j + 1;
                }
            }

            let end_line: i32 = ana_tk_line(j - 1);

            // Store function
            array_push(ana_fn_names, sp_store(fname));
            array_push(ana_fn_params, param_count);
            array_push(ana_fn_start, start_line);
            array_push(ana_fn_end, end_line);
            array_push(ana_fn_body_calls, calls);
            ana_fn_count = ana_fn_count + 1;

            i = j;
        }

        else {
            i = i + 1;
        }
    }
}

// ── Public API ───────────────────────────────────────

fn analyze_file(path: string) -> i32 {
    ana_init();
    ana_file = path;
    ana_source = read_file(path);
    if len(ana_source) == 0 {
        return 0 - 1;
    }
    ana_tokenize(ana_source);
    ana_extract_structure();
    return 0;
}

fn ana_get_file() -> string { return ana_file; }
fn ana_get_lines() -> i32 { return ana_src_lines; }
fn ana_get_func_count() -> i32 { return ana_fn_count; }
fn ana_get_global_count() -> i32 { return ana_gv_count; }
fn ana_get_use_count() -> i32 { return ana_use_count; }

fn ana_func_name(idx: i32) -> string {
    if idx < 0 || idx >= ana_fn_count { return ""; }
    return sp_get(array_get(ana_fn_names, idx));
}

fn ana_func_params(idx: i32) -> i32 {
    if idx < 0 || idx >= ana_fn_count { return 0; }
    return array_get(ana_fn_params, idx);
}

fn ana_func_start(idx: i32) -> i32 {
    if idx < 0 || idx >= ana_fn_count { return 0; }
    return array_get(ana_fn_start, idx);
}

fn ana_func_end(idx: i32) -> i32 {
    if idx < 0 || idx >= ana_fn_count { return 0; }
    return array_get(ana_fn_end, idx);
}

fn ana_func_lines(idx: i32) -> i32 {
    return ana_func_end(idx) - ana_func_start(idx) + 1;
}

fn ana_func_call_count(idx: i32) -> i32 {
    if idx < 0 || idx >= ana_fn_count { return 0; }
    return array_len(array_get(ana_fn_body_calls, idx));
}

fn ana_func_call_name(func_idx: i32, call_idx: i32) -> string {
    if func_idx < 0 || func_idx >= ana_fn_count { return ""; }
    let calls: i32 = array_get(ana_fn_body_calls, func_idx);
    if call_idx < 0 || call_idx >= array_len(calls) { return ""; }
    return sp_get(array_get(calls, call_idx));
}

fn ana_find_func(name: string) -> i32 {
    var i: i32 = 0;
    while i < ana_fn_count {
        if str_eq(ana_func_name(i), name) { return i; }
        i = i + 1;
    }
    return 0 - 1;
}

fn ana_global_name(idx: i32) -> string {
    if idx < 0 || idx >= ana_gv_count { return ""; }
    return sp_get(array_get(ana_gv_names, idx));
}

fn ana_global_type(idx: i32) -> string {
    if idx < 0 || idx >= ana_gv_count { return ""; }
    return sp_get(array_get(ana_gv_types, idx));
}

fn ana_use_path(idx: i32) -> string {
    if idx < 0 || idx >= ana_use_count { return ""; }
    return sp_get(array_get(ana_use_paths, idx));
}

// ── VM population ────────────────────────────────────
// Creates temporal VM bindings from analysis results.
// Each analysis is a "tick" — re-analyzing shows drift.

fn ana_populate_vm() {
    let tick: i32 = vm_get_tick();

    // File-level bindings
    env_bind("_file", val_str(ana_file), tick, "analyze");
    env_bind("_lines", val_i32(ana_src_lines), tick, "analyze");
    env_bind("_funcs", val_i32(ana_fn_count), tick, "analyze");
    env_bind("_globals", val_i32(ana_gv_count), tick, "analyze");
    env_bind("_uses", val_i32(ana_use_count), tick, "analyze");

    // Per-function bindings: fn.<name>.lines, fn.<name>.params, fn.<name>.calls
    var i: i32 = 0;
    while i < ana_fn_count {
        let name: string = ana_func_name(i);
        let key_lines: string = str_concat("fn.", str_concat(name, ".lines"));
        let key_params: string = str_concat("fn.", str_concat(name, ".params"));
        let key_calls: string = str_concat("fn.", str_concat(name, ".calls"));

        env_bind(key_lines, val_i32(ana_func_lines(i)), tick, "analyze");
        env_bind(key_params, val_i32(ana_func_params(i)), tick, "analyze");
        env_bind(key_calls, val_i32(ana_func_call_count(i)), tick, "analyze");
        i = i + 1;
    }
}

// ── Complexity metrics ───────────────────────────────

fn ana_avg_func_lines() -> i32 {
    if ana_fn_count == 0 { return 0; }
    var total: i32 = 0;
    var i: i32 = 0;
    while i < ana_fn_count {
        total = total + ana_func_lines(i);
        i = i + 1;
    }
    return total / ana_fn_count;
}

fn ana_max_func_lines() -> i32 {
    var max_l: i32 = 0;
    var i: i32 = 0;
    while i < ana_fn_count {
        let l: i32 = ana_func_lines(i);
        if l > max_l { max_l = l; }
        i = i + 1;
    }
    return max_l;
}

fn ana_max_func_name() -> string {
    var max_l: i32 = 0;
    var max_name: string = "";
    var i: i32 = 0;
    while i < ana_fn_count {
        let l: i32 = ana_func_lines(i);
        if l > max_l {
            max_l = l;
            max_name = ana_func_name(i);
        }
        i = i + 1;
    }
    return max_name;
}

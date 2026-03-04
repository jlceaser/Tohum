// strings.m — string utilities for M

fn starts_with(s: string, prefix: string) -> i32 {
    if len(prefix) > len(s) { return 0; }
    return str_eq(substr(s, 0, len(prefix)), prefix);
}

fn ends_with(s: string, suffix: string) -> i32 {
    if len(suffix) > len(s) { return 0; }
    return str_eq(substr(s, len(s) - len(suffix), len(suffix)), suffix);
}

fn repeat_str(s: string, n: i32) -> string {
    var result: string = "";
    var i: i32 = 0;
    while i < n {
        result = str_concat(result, s);
        i = i + 1;
    }
    return result;
}

fn contains(haystack: string, needle: string) -> i32 {
    if len(needle) > len(haystack) { return 0; }
    var i: i32 = 0;
    while i <= len(haystack) - len(needle) {
        if str_eq(substr(haystack, i, len(needle)), needle) { return 1; }
        i = i + 1;
    }
    return 0;
}

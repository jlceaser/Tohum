// Test program for argc/argv builtins
// Usage: mc self_codegen.m test_argv.m hello world

fn main() -> i32 {
    print("argc=");
    println(int_to_str(argc()));

    var i: i32 = 0;
    while i < argc() {
        print("argv(");
        print(int_to_str(i));
        print(")=");
        println(argv(i));
        i = i + 1;
    }

    return argc();
}

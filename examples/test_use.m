// Test multi-file compilation with use directive
use "lib/math.m";
use "lib/strings.m";

fn main() -> i32 {
    // Test math
    let result: i32 = add(3, mul(4, 5));
    print(int_to_str(result));
    print("|");

    print(int_to_str(square(7)));
    print("|");

    print(int_to_str(max(10, 20)));
    print("|");

    print(int_to_str(abs(0 - 42)));
    print("|");

    // Test strings
    if starts_with("hello world", "hello") { print("yes"); }
    else { print("no"); }
    print("|");

    if ends_with("test.m", ".m") { print("yes"); }
    else { print("no"); }
    print("|");

    print(repeat_str("ab", 3));
    print("|");

    if contains("machine language", "lang") { print("found"); }
    else { print("nope"); }

    println("");
    return result;
}

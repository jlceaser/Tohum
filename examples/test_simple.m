// Simple test for M -> C transpiler
fn fib(n: i32) -> i32 {
    if n <= 1 { return n; }
    return fib(n - 1) + fib(n - 2);
}

fn main() -> i32 {
    let result: i32 = fib(10);
    print(int_to_str(result));
    println("");
    return result;
}

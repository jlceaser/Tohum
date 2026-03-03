// Collatz conjecture: how many steps to reach 1?

fn collatz_steps(n: i32) -> i32 {
    var steps: i32 = 0;
    var x: i32 = n;
    while x != 1 {
        if x % 2 == 0 {
            x = x / 2;
        } else {
            x = x * 3 + 1;
        }
        steps = steps + 1;
    }
    return steps;
}

fn main() -> i32 {
    var n: i32 = 1;
    while n <= 20 {
        print(n);
        print(" -> ");
        println(collatz_steps(n));
        n = n + 1;
    }
    return 0;
}

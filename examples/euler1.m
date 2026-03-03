// Project Euler #1: sum of multiples of 3 or 5 below 1000

fn main() -> i32 {
    var sum: i32 = 0;
    var i: i32 = 1;
    while i < 1000 {
        if i % 3 == 0 {
            sum = sum + i;
        } else if i % 5 == 0 {
            sum = sum + i;
        }
        i = i + 1;
    }
    println(sum);
    return 0;
}

// math.m — basic math utilities for M

fn add(a: i32, b: i32) -> i32 { return a + b; }
fn mul(a: i32, b: i32) -> i32 { return a * b; }
fn square(n: i32) -> i32 { return n * n; }
fn abs(n: i32) -> i32 { if n < 0 { return 0 - n; } return n; }
fn max(a: i32, b: i32) -> i32 { if a > b { return a; } return b; }
fn min(a: i32, b: i32) -> i32 { if a < b { return a; } return b; }

# M Language Specification — v0.1

> M: the bone language. Everything above stands on this.

## Philosophy

M is not a general-purpose language. M exists so that Tohum can exist
without depending on anything we didn't write. M is minimal, explicit,
and transparent. No hidden behavior. No magic.

## Core Principles

1. **No hidden allocations.** Every byte of memory is explicitly managed.
2. **No implicit conversions.** Types don't silently change.
3. **No exceptions.** Errors are values, returned explicitly.
4. **No runtime.** M compiles to machine code. No garbage collector, no runtime library.
5. **What you write is what runs.** No optimizer rewrites your intent.

## Types

### Primitive Types

| Type  | Size    | Description          |
|-------|---------|----------------------|
| `u8`  | 1 byte  | Unsigned 8-bit       |
| `u16` | 2 bytes | Unsigned 16-bit      |
| `u32` | 4 bytes | Unsigned 32-bit      |
| `u64` | 8 bytes | Unsigned 64-bit      |
| `i8`  | 1 byte  | Signed 8-bit         |
| `i16` | 2 bytes | Signed 16-bit        |
| `i32` | 4 bytes | Signed 32-bit        |
| `i64` | 8 bytes | Signed 64-bit        |
| `f64` | 8 bytes | 64-bit float         |
| `bool`| 1 byte  | true or false        |
| `void`| 0 bytes | No value             |

### Pointers

```m
ptr<u8>       // pointer to u8
ptr<MyStruct> // pointer to struct
```

No null pointers by default. A pointer either points to something or it doesn't exist.

### Arrays

```m
[u8; 256]     // fixed-size array: 256 bytes
[]u8          // slice: pointer + length (no ownership)
```

## Declarations

### Variables

```m
let x: i32 = 42;         // immutable by default
var count: u64 = 0;       // mutable
let name: []u8 = "tohum"; // string is just a byte slice
```

### Functions

```m
fn add(a: i32, b: i32) -> i32 {
    return a + b;
}

fn divide(a: f64, b: f64) -> (f64, bool) {
    if b == 0.0 {
        return (0.0, false);  // error as value
    }
    return (a / b, true);
}
```

### Structs

```m
struct Point {
    x: f64,
    y: f64,
}

fn origin() -> Point {
    return Point { x: 0.0, y: 0.0 };
}
```

## Memory

### Explicit allocation

```m
let p: ptr<Point> = alloc(Point);  // allocate one Point
free(p);                            // free it

let arr: ptr<u8> = alloc_n(u8, 1024);  // allocate 1024 bytes
free_n(arr, u8, 1024);                  // free with size
```

No malloc/free — M has its own allocation words that track sizes.

### Stack allocation (default)

```m
let p: Point = origin();  // on the stack, no allocation
```

## Control Flow

```m
if condition {
    // ...
} else {
    // ...
}

while condition {
    // ...
}

// No for loops yet. While is enough.
```

## Strings

There is no string type. Strings are `[]u8` — byte slices.
The language provides no string operations built in.
String utilities are written in M itself, as a library.

## Entry Point

```m
fn main() -> i32 {
    // ...
    return 0;
}
```

## What M Does NOT Have

- No classes, no inheritance, no interfaces
- No generics (yet — maybe later, if needed)
- No closures, no lambdas
- No garbage collector
- No exceptions, no try/catch
- No operator overloading
- No macros (yet)
- No import system (yet — files are concatenated)

## Bootstrap Plan

1. First M compiler written in C (minimal, just enough to compile M)
2. M compiler rewritten in M (self-hosting)
3. C bootstrap compiler discarded
4. All future M development happens in M

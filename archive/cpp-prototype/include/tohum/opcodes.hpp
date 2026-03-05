#pragma once

#include <cstdint>

namespace tohum {

// Tohum VM bytecode instructions
// Each instruction is a single byte opcode, optionally followed by operands
enum class OpCode : uint8_t {
    // Stack operations
    PUSH_NIL,       // push nil onto stack
    PUSH_TRUE,      // push true (confidence 1.0)
    PUSH_FALSE,     // push false (confidence 1.0)
    PUSH_NUMBER,    // push certain number: [f64]
    PUSH_APPROX,    // push approximate number: [f64 value] [f64 confidence]
    PUSH_STRING,    // push string: [u16 length] [bytes...]
    POP,            // discard top of stack

    // Variable operations
    BIND,           // bind top of stack to name: [u16 name_index]
                    // does NOT overwrite — appends to timeline
    LOAD,           // push current value of binding: [u16 name_index]

    // Arithmetic (propagates uncertainty)
    ADD,            // a + b
    SUB,            // a - b
    MUL,            // a * b
    DIV,            // a / b
    NEG,            // -a

    // Comparison (produces boolean with propagated confidence)
    EQ,             // a == b
    NEQ,            // a != b
    LT,             // a < b
    GT,             // a > b
    LTE,            // a <= b
    GTE,            // a >= b

    // Logic
    AND,            // logical and (confidence-aware)
    OR,             // logical or (confidence-aware)
    NOT,            // logical not

    // Control flow
    JUMP,           // unconditional jump: [i16 offset]
    JUMP_IF_FALSE,  // conditional jump: [i16 offset]

    // Temporal / reflection
    HISTORY,        // push history of binding: [u16 name_index]
    REFLECT,        // push VM state as structured value
    DRIFT,          // push drift report since last persist
    FORGET,         // actively forget a binding: [u16 name_index]

    // Persistence
    PERSIST,        // save VM state to disk
    RESTORE,        // load VM state from disk

    // I/O
    PRINT,          // print top of stack

    // System
    HALT,           // stop execution
    NOP,            // do nothing
};

} // namespace tohum

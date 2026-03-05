#pragma once

#include "tohum/opcodes.hpp"
#include "tohum/value.hpp"

#include <cstdint>
#include <filesystem>
#include <string>
#include <unordered_map>
#include <vector>

namespace tohum {

// A chunk of bytecode — a compiled unit of Tohum code
struct Chunk {
    std::vector<uint8_t> code;
    std::vector<std::string> names;   // name table (for BIND/LOAD)
    std::vector<double> numbers;       // number constants

    // Helpers for building bytecode
    void emit(OpCode op);
    void emit(OpCode op, uint16_t operand);
    void emit_number(double value);
    void emit_approx(double value, double confidence);
    void emit_string(const std::string& str);
    uint16_t add_name(const std::string& name);
    uint16_t add_number(double value);
};

// The Tohum virtual machine
// This is the çekirdek — the core.
class VM {
public:
    explicit VM(std::filesystem::path state_path = "");

    // Execute a chunk of bytecode
    enum class Result { OK, RUNTIME_ERROR, HALTED };
    Result execute(const Chunk& chunk);

    // REPL support
    Value* get_binding(const std::string& name);
    std::vector<std::string> all_bindings() const;

    // Temporal operations
    std::string format_history(const std::string& name) const;
    std::string format_reflect() const;
    std::string format_drift() const;

    // Persistence
    bool persist() const;
    bool restore();
    bool has_state_file() const;

    // Stats
    std::size_t binding_count() const { return env_.size(); }
    std::size_t stack_depth() const { return stack_.size(); }

    // Last result (top of stack after execution)
    const Value& last_result() const { return last_result_; }

private:
    // Stack
    std::vector<Value> stack_;
    void push(Value v);
    Value pop();
    Value& peek();

    // Environment — temporal bindings
    std::unordered_map<std::string, Value> env_;

    // Snapshot of env at last persist (for drift detection)
    std::unordered_map<std::string, std::size_t> snapshot_lengths_;

    // State file path for persistence
    std::filesystem::path state_path_;

    // Last result for REPL display
    Value last_result_ = Value::nil();

    // Instruction pointer helpers
    uint8_t read_byte(const Chunk& chunk, std::size_t& ip);
    uint16_t read_u16(const Chunk& chunk, std::size_t& ip);
    int16_t read_i16(const Chunk& chunk, std::size_t& ip);
    double read_f64(const Chunk& chunk, std::size_t& ip);

    // Runtime error
    void runtime_error(const std::string& msg);
    bool had_error_ = false;
};

} // namespace tohum

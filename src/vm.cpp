#include "tohum/vm.hpp"

#include <chrono>
#include <cstring>
#include <ctime>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>

namespace tohum {

// --- Chunk building ---

void Chunk::emit(OpCode op) {
    code.push_back(static_cast<uint8_t>(op));
}

void Chunk::emit(OpCode op, uint16_t operand) {
    code.push_back(static_cast<uint8_t>(op));
    code.push_back(static_cast<uint8_t>(operand >> 8));
    code.push_back(static_cast<uint8_t>(operand & 0xFF));
}

void Chunk::emit_number(double value) {
    code.push_back(static_cast<uint8_t>(OpCode::PUSH_NUMBER));
    // Encode f64 as 8 bytes
    uint8_t bytes[8];
    std::memcpy(bytes, &value, 8);
    for (int i = 0; i < 8; i++) code.push_back(bytes[i]);
}

void Chunk::emit_approx(double value, double confidence) {
    code.push_back(static_cast<uint8_t>(OpCode::PUSH_APPROX));
    uint8_t bytes[8];
    std::memcpy(bytes, &value, 8);
    for (int i = 0; i < 8; i++) code.push_back(bytes[i]);
    std::memcpy(bytes, &confidence, 8);
    for (int i = 0; i < 8; i++) code.push_back(bytes[i]);
}

void Chunk::emit_string(const std::string& str) {
    code.push_back(static_cast<uint8_t>(OpCode::PUSH_STRING));
    uint16_t len = static_cast<uint16_t>(str.size());
    code.push_back(static_cast<uint8_t>(len >> 8));
    code.push_back(static_cast<uint8_t>(len & 0xFF));
    for (char c : str) code.push_back(static_cast<uint8_t>(c));
}

uint16_t Chunk::add_name(const std::string& name) {
    for (uint16_t i = 0; i < names.size(); i++) {
        if (names[i] == name) return i;
    }
    names.push_back(name);
    return static_cast<uint16_t>(names.size() - 1);
}

uint16_t Chunk::add_number(double value) {
    numbers.push_back(value);
    return static_cast<uint16_t>(numbers.size() - 1);
}

// --- VM ---

VM::VM(std::filesystem::path state_path)
    : state_path_(std::move(state_path)) {
    if (!state_path_.empty()) {
        restore(); // try to load previous state
    }
}

void VM::push(Value v) {
    stack_.push_back(std::move(v));
}

Value VM::pop() {
    if (stack_.empty()) {
        runtime_error("stack underflow");
        return Value::nil();
    }
    Value v = std::move(stack_.back());
    stack_.pop_back();
    return v;
}

Value& VM::peek() {
    if (stack_.empty()) {
        runtime_error("stack underflow on peek");
        static Value nil = Value::nil();
        return nil;
    }
    return stack_.back();
}

uint8_t VM::read_byte(const Chunk& chunk, std::size_t& ip) {
    return chunk.code[ip++];
}

uint16_t VM::read_u16(const Chunk& chunk, std::size_t& ip) {
    uint8_t hi = chunk.code[ip++];
    uint8_t lo = chunk.code[ip++];
    return (static_cast<uint16_t>(hi) << 8) | lo;
}

int16_t VM::read_i16(const Chunk& chunk, std::size_t& ip) {
    uint16_t u = read_u16(chunk, ip);
    return static_cast<int16_t>(u);
}

double VM::read_f64(const Chunk& chunk, std::size_t& ip) {
    double val;
    std::memcpy(&val, &chunk.code[ip], 8);
    ip += 8;
    return val;
}

void VM::runtime_error(const std::string& msg) {
    std::cerr << "tohum runtime error: " << msg << "\n";
    had_error_ = true;
}

VM::Result VM::execute(const Chunk& chunk) {
    had_error_ = false;
    std::size_t ip = 0;

    while (ip < chunk.code.size()) {
        if (had_error_) return Result::RUNTIME_ERROR;

        auto op = static_cast<OpCode>(read_byte(chunk, ip));

        switch (op) {

        case OpCode::NOP:
            break;

        case OpCode::HALT:
            if (!stack_.empty()) last_result_ = stack_.back();
            return Result::HALTED;

        case OpCode::PUSH_NIL:
            push(Value::nil());
            break;

        case OpCode::PUSH_TRUE:
            push(Value::certain(true));
            break;

        case OpCode::PUSH_FALSE:
            push(Value::certain(false));
            break;

        case OpCode::PUSH_NUMBER: {
            double val = read_f64(chunk, ip);
            push(Value::certain(val));
            break;
        }

        case OpCode::PUSH_APPROX: {
            double val = read_f64(chunk, ip);
            double conf = read_f64(chunk, ip);
            push(Value::approximate(val, conf));
            break;
        }

        case OpCode::PUSH_STRING: {
            uint16_t len = read_u16(chunk, ip);
            std::string str(reinterpret_cast<const char*>(&chunk.code[ip]), len);
            ip += len;
            push(Value::certain(std::move(str)));
            break;
        }

        case OpCode::POP:
            pop();
            break;

        case OpCode::BIND: {
            uint16_t idx = read_u16(chunk, ip);
            const std::string& name = chunk.names[idx];
            Value val = pop();
            auto it = env_.find(name);
            if (it != env_.end()) {
                // Existing binding — append to timeline, don't overwrite
                it->second.push(val.data(), val.confidence(), "rebind");
            } else {
                env_.emplace(name, std::move(val));
            }
            break;
        }

        case OpCode::LOAD: {
            uint16_t idx = read_u16(chunk, ip);
            const std::string& name = chunk.names[idx];
            auto it = env_.find(name);
            if (it == env_.end()) {
                runtime_error("undefined binding: " + name);
                push(Value::nil());
            } else if (it->second.is_forgotten()) {
                runtime_error("binding was forgotten: " + name);
                push(Value::nil());
            } else {
                push(it->second);
            }
            break;
        }

        case OpCode::ADD: {
            Value b = pop();
            Value a = pop();
            double result = a.as_number() + b.as_number();
            Confidence conf = propagate_confidence(a.confidence(), b.confidence());
            push(Value::approximate(result, conf, "add"));
            break;
        }

        case OpCode::SUB: {
            Value b = pop();
            Value a = pop();
            double result = a.as_number() - b.as_number();
            Confidence conf = propagate_confidence(a.confidence(), b.confidence());
            push(Value::approximate(result, conf, "sub"));
            break;
        }

        case OpCode::MUL: {
            Value b = pop();
            Value a = pop();
            double result = a.as_number() * b.as_number();
            Confidence conf = propagate_confidence(a.confidence(), b.confidence());
            push(Value::approximate(result, conf, "mul"));
            break;
        }

        case OpCode::DIV: {
            Value b = pop();
            Value a = pop();
            if (b.as_number() == 0.0) {
                runtime_error("division by zero");
                push(Value::nil());
            } else {
                double result = a.as_number() / b.as_number();
                Confidence conf = propagate_confidence(a.confidence(), b.confidence());
                push(Value::approximate(result, conf, "div"));
            }
            break;
        }

        case OpCode::NEG: {
            Value a = pop();
            push(Value::approximate(-a.as_number(), a.confidence(), "neg"));
            break;
        }

        case OpCode::EQ: {
            Value b = pop();
            Value a = pop();
            bool result = (a.as_number() == b.as_number());
            Confidence conf = propagate_confidence(a.confidence(), b.confidence());
            push(Value::approximate(result, conf, "eq"));
            break;
        }

        case OpCode::NEQ: {
            Value b = pop();
            Value a = pop();
            bool result = (a.as_number() != b.as_number());
            Confidence conf = propagate_confidence(a.confidence(), b.confidence());
            push(Value::approximate(result, conf, "neq"));
            break;
        }

        case OpCode::LT: {
            Value b = pop();
            Value a = pop();
            bool result = (a.as_number() < b.as_number());
            Confidence conf = propagate_confidence(a.confidence(), b.confidence());
            push(Value::approximate(result, conf, "lt"));
            break;
        }

        case OpCode::GT: {
            Value b = pop();
            Value a = pop();
            bool result = (a.as_number() > b.as_number());
            Confidence conf = propagate_confidence(a.confidence(), b.confidence());
            push(Value::approximate(result, conf, "gt"));
            break;
        }

        case OpCode::LTE: {
            Value b = pop();
            Value a = pop();
            bool result = (a.as_number() <= b.as_number());
            Confidence conf = propagate_confidence(a.confidence(), b.confidence());
            push(Value::approximate(result, conf, "lte"));
            break;
        }

        case OpCode::GTE: {
            Value b = pop();
            Value a = pop();
            bool result = (a.as_number() >= b.as_number());
            Confidence conf = propagate_confidence(a.confidence(), b.confidence());
            push(Value::approximate(result, conf, "gte"));
            break;
        }

        case OpCode::AND: {
            Value b = pop();
            Value a = pop();
            bool result = a.truthy() && b.truthy();
            Confidence conf = propagate_confidence(a.confidence(), b.confidence());
            push(Value::approximate(result, conf, "and"));
            break;
        }

        case OpCode::OR: {
            Value b = pop();
            Value a = pop();
            bool result = a.truthy() || b.truthy();
            Confidence conf = propagate_confidence(a.confidence(), b.confidence());
            push(Value::approximate(result, conf, "or"));
            break;
        }

        case OpCode::NOT: {
            Value a = pop();
            push(Value::approximate(!a.truthy(), a.confidence(), "not"));
            break;
        }

        case OpCode::JUMP: {
            int16_t offset = read_i16(chunk, ip);
            ip = static_cast<std::size_t>(static_cast<int64_t>(ip) + offset);
            break;
        }

        case OpCode::JUMP_IF_FALSE: {
            int16_t offset = read_i16(chunk, ip);
            if (!peek().truthy()) {
                ip = static_cast<std::size_t>(static_cast<int64_t>(ip) + offset);
            }
            pop();
            break;
        }

        case OpCode::PRINT: {
            Value v = pop();
            std::cout << "  = " << v.display() << "\n";
            last_result_ = std::move(v);
            break;
        }

        case OpCode::HISTORY: {
            uint16_t idx = read_u16(chunk, ip);
            const std::string& name = chunk.names[idx];
            std::cout << format_history(name);
            break;
        }

        case OpCode::REFLECT: {
            std::cout << format_reflect();
            break;
        }

        case OpCode::DRIFT: {
            std::cout << format_drift();
            break;
        }

        case OpCode::FORGET: {
            uint16_t idx = read_u16(chunk, ip);
            const std::string& name = chunk.names[idx];
            auto it = env_.find(name);
            if (it != env_.end()) {
                it->second.forget();
            }
            break;
        }

        case OpCode::PERSIST:
            persist();
            break;

        case OpCode::RESTORE:
            restore();
            break;

        } // switch
    }

    if (!stack_.empty()) {
        last_result_ = stack_.back();
    }

    return had_error_ ? Result::RUNTIME_ERROR : Result::OK;
}

Value* VM::get_binding(const std::string& name) {
    auto it = env_.find(name);
    if (it == env_.end()) return nullptr;
    return &it->second;
}

std::vector<std::string> VM::all_bindings() const {
    std::vector<std::string> names;
    names.reserve(env_.size());
    for (const auto& [name, _] : env_) {
        names.push_back(name);
    }
    return names;
}

static std::string format_timepoint(std::chrono::system_clock::time_point tp) {
    auto time = std::chrono::system_clock::to_time_t(tp);
    std::tm tm{};
#ifdef _WIN32
    localtime_s(&tm, &time);
#else
    localtime_r(&time, &tm);
#endif
    std::ostringstream out;
    out << std::put_time(&tm, "%Y-%m-%d %H:%M:%S");
    return out.str();
}

std::string VM::format_history(const std::string& name) const {
    auto it = env_.find(name);
    if (it == env_.end()) return "  (undefined)\n";

    const auto& history = it->second.history();
    std::ostringstream out;
    for (std::size_t i = 0; i < history.size(); i++) {
        const auto& snap = history[i];
        Value temp = (snap.confidence >= CERTAIN)
            ? Value::certain(snap.data)
            : Value::approximate(snap.data, snap.confidence);

        out << "  [" << i << "] "
            << format_timepoint(snap.when.timestamp)
            << " — " << temp.display()
            << " (" << snap.when.source << ")\n";
    }
    return out.str();
}

std::string VM::format_reflect() const {
    std::ostringstream out;

    std::size_t certain_count = 0;
    std::size_t approx_count = 0;
    std::size_t forgotten_count = 0;

    for (const auto& [name, val] : env_) {
        if (val.is_forgotten()) forgotten_count++;
        else if (val.is_certain()) certain_count++;
        else approx_count++;
    }

    out << "  bindings: " << env_.size() << "\n";
    out << "  certain: " << certain_count << "\n";
    out << "  approximate: " << approx_count << "\n";
    if (forgotten_count > 0) {
        out << "  forgotten: " << forgotten_count << "\n";
    }

    // Find most changed binding
    std::string most_changed;
    std::size_t max_history = 0;
    for (const auto& [name, val] : env_) {
        if (val.history_length() > max_history) {
            max_history = val.history_length();
            most_changed = name;
        }
    }
    if (max_history > 1) {
        out << "  most changed: " << most_changed
            << " (" << max_history << " entries)\n";
    }

    return out.str();
}

std::string VM::format_drift() const {
    if (snapshot_lengths_.empty()) {
        return "  (no previous snapshot — persist first)\n";
    }

    std::ostringstream out;
    std::size_t new_bindings = 0;
    std::size_t changed_bindings = 0;
    std::size_t stable_bindings = 0;

    for (const auto& [name, val] : env_) {
        auto snap_it = snapshot_lengths_.find(name);
        if (snap_it == snapshot_lengths_.end()) {
            new_bindings++;
            out << "  + " << name << " (new)\n";
        } else if (val.history_length() > snap_it->second) {
            changed_bindings++;
            out << "  ~ " << name << " (changed "
                << (val.history_length() - snap_it->second) << " times)\n";
        } else {
            stable_bindings++;
        }
    }

    out << "  stable: " << stable_bindings
        << ", changed: " << changed_bindings
        << ", new: " << new_bindings << "\n";

    return out.str();
}

// --- Persistence ---
// Simple text-based format for now. Will evolve.

bool VM::persist() const {
    if (state_path_.empty()) return false;

    std::ofstream f(state_path_, std::ios::binary);
    if (!f) return false;

    // Write number of bindings
    uint32_t count = static_cast<uint32_t>(env_.size());
    f.write(reinterpret_cast<const char*>(&count), 4);

    for (const auto& [name, val] : env_) {
        // Write name
        uint16_t name_len = static_cast<uint16_t>(name.size());
        f.write(reinterpret_cast<const char*>(&name_len), 2);
        f.write(name.data(), name_len);

        // Write forgotten flag
        uint8_t forgotten = val.is_forgotten() ? 1 : 0;
        f.write(reinterpret_cast<const char*>(&forgotten), 1);

        // Write timeline length
        uint32_t hist_len = static_cast<uint32_t>(val.history().size());
        f.write(reinterpret_cast<const char*>(&hist_len), 4);

        for (const auto& snap : val.history()) {
            // Write confidence
            f.write(reinterpret_cast<const char*>(&snap.confidence), 8);

            // Write timestamp as epoch seconds
            auto epoch = std::chrono::system_clock::to_time_t(snap.when.timestamp);
            int64_t ts = static_cast<int64_t>(epoch);
            f.write(reinterpret_cast<const char*>(&ts), 8);

            // Write source
            uint16_t src_len = static_cast<uint16_t>(snap.when.source.size());
            f.write(reinterpret_cast<const char*>(&src_len), 2);
            f.write(snap.when.source.data(), src_len);

            // Write data type and value
            if (std::holds_alternative<std::monostate>(snap.data)) {
                uint8_t type = 0;
                f.write(reinterpret_cast<const char*>(&type), 1);
            } else if (std::holds_alternative<double>(snap.data)) {
                uint8_t type = 1;
                f.write(reinterpret_cast<const char*>(&type), 1);
                double val = std::get<double>(snap.data);
                f.write(reinterpret_cast<const char*>(&val), 8);
            } else if (std::holds_alternative<bool>(snap.data)) {
                uint8_t type = 2;
                f.write(reinterpret_cast<const char*>(&type), 1);
                uint8_t val = std::get<bool>(snap.data) ? 1 : 0;
                f.write(reinterpret_cast<const char*>(&val), 1);
            } else if (std::holds_alternative<std::string>(snap.data)) {
                uint8_t type = 3;
                f.write(reinterpret_cast<const char*>(&type), 1);
                const auto& s = std::get<std::string>(snap.data);
                uint32_t s_len = static_cast<uint32_t>(s.size());
                f.write(reinterpret_cast<const char*>(&s_len), 4);
                f.write(s.data(), s_len);
            }
        }
    }

    return f.good();
}

bool VM::restore() {
    if (state_path_.empty() || !std::filesystem::exists(state_path_)) return false;

    std::ifstream f(state_path_, std::ios::binary);
    if (!f) return false;

    uint32_t count;
    f.read(reinterpret_cast<char*>(&count), 4);
    if (!f) return false;

    env_.clear();
    snapshot_lengths_.clear();

    for (uint32_t i = 0; i < count; i++) {
        // Read name
        uint16_t name_len;
        f.read(reinterpret_cast<char*>(&name_len), 2);
        std::string name(name_len, '\0');
        f.read(name.data(), name_len);

        // Read forgotten flag
        uint8_t forgotten;
        f.read(reinterpret_cast<char*>(&forgotten), 1);

        // Read timeline
        uint32_t hist_len;
        f.read(reinterpret_cast<char*>(&hist_len), 4);

        Value val = Value::nil();
        bool first = true;

        for (uint32_t j = 0; j < hist_len; j++) {
            double confidence;
            f.read(reinterpret_cast<char*>(&confidence), 8);

            int64_t ts;
            f.read(reinterpret_cast<char*>(&ts), 8);
            auto timepoint = std::chrono::system_clock::from_time_t(static_cast<time_t>(ts));

            uint16_t src_len;
            f.read(reinterpret_cast<char*>(&src_len), 2);
            std::string source(src_len, '\0');
            f.read(source.data(), src_len);

            uint8_t type;
            f.read(reinterpret_cast<char*>(&type), 1);

            RawValue data;
            if (type == 0) {
                data = std::monostate{};
            } else if (type == 1) {
                double d;
                f.read(reinterpret_cast<char*>(&d), 8);
                data = d;
            } else if (type == 2) {
                uint8_t b;
                f.read(reinterpret_cast<char*>(&b), 1);
                data = static_cast<bool>(b);
            } else if (type == 3) {
                uint32_t s_len;
                f.read(reinterpret_cast<char*>(&s_len), 4);
                std::string s(s_len, '\0');
                f.read(s.data(), s_len);
                data = std::move(s);
            }

            if (first) {
                val = (confidence >= CERTAIN)
                    ? Value::certain(std::move(data), std::move(source))
                    : Value::approximate(std::move(data), confidence, std::move(source));
                first = false;
            } else {
                val.push(std::move(data), confidence, std::move(source));
            }
        }

        if (forgotten) val.forget();

        snapshot_lengths_[name] = val.history_length();
        env_.emplace(std::move(name), std::move(val));
    }

    return f.good();
}

bool VM::has_state_file() const {
    return !state_path_.empty() && std::filesystem::exists(state_path_);
}

} // namespace tohum

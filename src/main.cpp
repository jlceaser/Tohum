#include "tohum/vm.hpp"

#include <filesystem>
#include <iostream>
#include <sstream>
#include <string>

using namespace tohum;

static void print_welcome(const VM& vm) {
    std::cout << "\n";
    std::cout << "  tohum v0.1.0\n";
    std::cout << "  Temporal computation with native uncertainty.\n";
    std::cout << "\n";

    if (vm.has_state_file()) {
        std::cout << "  (restored " << vm.binding_count() << " bindings from previous session)\n";
    } else {
        std::cout << "  (fresh session — no previous state)\n";
    }

    std::cout << "\n";
    std::cout << "  Commands:\n";
    std::cout << "    x = 42          bind a certain value\n";
    std::cout << "    y = ~3.14       bind an approximate value\n";
    std::cout << "    y = ~3.14@0.8   approximate with explicit confidence\n";
    std::cout << "    x + y           arithmetic (uncertainty propagates)\n";
    std::cout << "    history(x)      show value timeline\n";
    std::cout << "    reflect()       show VM state\n";
    std::cout << "    drift()         show changes since last save\n";
    std::cout << "    forget(x)       actively forget a binding\n";
    std::cout << "    save            persist state to disk\n";
    std::cout << "    exit            quit (auto-saves)\n";
    std::cout << "\n";
}

// Minimal expression parser for the REPL
// This is a bridge until the real compiler exists (Phase 2)
// It handles the core interactions: bind, load, arithmetic, builtins

static bool is_identifier_char(char c) {
    return std::isalnum(c) || c == '_';
}

static std::string trim(const std::string& s) {
    auto start = s.find_first_not_of(" \t\r\n");
    if (start == std::string::npos) return "";
    auto end = s.find_last_not_of(" \t\r\n");
    return s.substr(start, end - start + 1);
}

static void execute_line(VM& vm, const std::string& input) {
    std::string line = trim(input);
    if (line.empty()) return;

    Chunk chunk;

    // Built-in commands
    if (line == "reflect()") {
        chunk.emit(OpCode::REFLECT);
        vm.execute(chunk);
        return;
    }

    if (line == "drift()") {
        chunk.emit(OpCode::DRIFT);
        vm.execute(chunk);
        return;
    }

    if (line == "save") {
        chunk.emit(OpCode::PERSIST);
        vm.execute(chunk);
        std::cout << "  (saved)\n";
        return;
    }

    // history(name)
    if (line.size() > 9 && line.substr(0, 8) == "history(" && line.back() == ')') {
        std::string name = line.substr(8, line.size() - 9);
        name = trim(name);
        uint16_t idx = chunk.add_name(name);
        chunk.emit(OpCode::HISTORY, idx);
        vm.execute(chunk);
        return;
    }

    // forget(name)
    if (line.size() > 8 && line.substr(0, 7) == "forget(" && line.back() == ')') {
        std::string name = line.substr(7, line.size() - 8);
        name = trim(name);
        uint16_t idx = chunk.add_name(name);
        chunk.emit(OpCode::FORGET, idx);
        vm.execute(chunk);
        std::cout << "  (" << name << " forgotten)\n";
        return;
    }

    // Assignment: name = expr
    auto eq_pos = line.find('=');
    if (eq_pos != std::string::npos && eq_pos > 0 && line[eq_pos - 1] != '!'
        && line[eq_pos - 1] != '<' && line[eq_pos - 1] != '>') {
        // Check it's not == comparison
        if (eq_pos + 1 < line.size() && line[eq_pos + 1] == '=') {
            // It's == comparison, fall through
        } else {
            std::string name = trim(line.substr(0, eq_pos));
            std::string expr = trim(line.substr(eq_pos + 1));

            // Check name is valid identifier
            bool valid = !name.empty() && (std::isalpha(name[0]) || name[0] == '_');
            for (char c : name) valid = valid && is_identifier_char(c);

            if (valid) {
                // Parse the expression value
                if (expr.empty()) {
                    chunk.emit(OpCode::PUSH_NIL);
                } else if (expr[0] == '~') {
                    // Approximate value
                    std::string num_str = expr.substr(1);
                    double conf = 0.9; // default confidence for ~

                    auto at_pos = num_str.find('@');
                    if (at_pos != std::string::npos) {
                        conf = std::stod(num_str.substr(at_pos + 1));
                        num_str = num_str.substr(0, at_pos);
                    }

                    double val = std::stod(trim(num_str));
                    chunk.emit_approx(val, conf);
                } else if (expr == "true") {
                    chunk.emit(OpCode::PUSH_TRUE);
                } else if (expr == "false") {
                    chunk.emit(OpCode::PUSH_FALSE);
                } else if (expr == "nil") {
                    chunk.emit(OpCode::PUSH_NIL);
                } else if (expr[0] == '"' && expr.back() == '"') {
                    chunk.emit_string(expr.substr(1, expr.size() - 2));
                } else if (std::isdigit(expr[0]) || (expr[0] == '-' && expr.size() > 1)) {
                    chunk.emit_number(std::stod(expr));
                } else {
                    // Try to evaluate as expression with one operator
                    // Simple: a + b, a - b, a * b, a / b
                    bool found_op = false;
                    for (std::size_t i = 1; i < expr.size() - 1; i++) {
                        char c = expr[i];
                        if (c == '+' || c == '-' || c == '*' || c == '/') {
                            // Check it's not part of a number
                            if (c == '-' && i > 0 && expr[i-1] == ' ') {
                                // Might be subtraction
                            }
                            std::string left = trim(expr.substr(0, i));
                            std::string right = trim(expr.substr(i + 1));

                            if (!left.empty() && !right.empty()) {
                                // Load or push left
                                if (std::isdigit(left[0])) {
                                    chunk.emit_number(std::stod(left));
                                } else if (left[0] == '~') {
                                    std::string ns = left.substr(1);
                                    double co = 0.9;
                                    auto ap = ns.find('@');
                                    if (ap != std::string::npos) {
                                        co = std::stod(ns.substr(ap + 1));
                                        ns = ns.substr(0, ap);
                                    }
                                    chunk.emit_approx(std::stod(trim(ns)), co);
                                } else {
                                    uint16_t li = chunk.add_name(left);
                                    chunk.emit(OpCode::LOAD, li);
                                }

                                // Load or push right
                                if (std::isdigit(right[0])) {
                                    chunk.emit_number(std::stod(right));
                                } else if (right[0] == '~') {
                                    std::string ns = right.substr(1);
                                    double co = 0.9;
                                    auto ap = ns.find('@');
                                    if (ap != std::string::npos) {
                                        co = std::stod(ns.substr(ap + 1));
                                        ns = ns.substr(0, ap);
                                    }
                                    chunk.emit_approx(std::stod(trim(ns)), co);
                                } else {
                                    uint16_t ri = chunk.add_name(right);
                                    chunk.emit(OpCode::LOAD, ri);
                                }

                                // Emit operator
                                switch (c) {
                                    case '+': chunk.emit(OpCode::ADD); break;
                                    case '-': chunk.emit(OpCode::SUB); break;
                                    case '*': chunk.emit(OpCode::MUL); break;
                                    case '/': chunk.emit(OpCode::DIV); break;
                                }

                                found_op = true;
                                break;
                            }
                        }
                    }

                    if (!found_op) {
                        // Try as variable reference
                        uint16_t vi = chunk.add_name(expr);
                        chunk.emit(OpCode::LOAD, vi);
                    }
                }

                uint16_t name_idx = chunk.add_name(name);
                chunk.emit(OpCode::BIND, name_idx);
                vm.execute(chunk);
                return;
            }
        }
    }

    // Expression evaluation (not assignment)
    // Simple: single value, variable, or binary op
    if (line == "true") {
        chunk.emit(OpCode::PUSH_TRUE);
    } else if (line == "false") {
        chunk.emit(OpCode::PUSH_FALSE);
    } else if (line == "nil") {
        chunk.emit(OpCode::PUSH_NIL);
    } else if (line[0] == '~') {
        std::string num_str = line.substr(1);
        double conf = 0.9;
        auto at_pos = num_str.find('@');
        if (at_pos != std::string::npos) {
            conf = std::stod(num_str.substr(at_pos + 1));
            num_str = num_str.substr(0, at_pos);
        }
        chunk.emit_approx(std::stod(trim(num_str)), conf);
    } else if (std::isdigit(line[0]) || (line[0] == '-' && line.size() > 1 && std::isdigit(line[1]))) {
        chunk.emit_number(std::stod(line));
    } else if (line[0] == '"' && line.back() == '"') {
        chunk.emit_string(line.substr(1, line.size() - 2));
    } else {
        // Try binary expression or variable
        bool found_op = false;
        for (std::size_t i = 1; i < line.size() - 1; i++) {
            char c = line[i];
            if (c == '+' || c == '-' || c == '*' || c == '/') {
                std::string left = trim(line.substr(0, i));
                std::string right = trim(line.substr(i + 1));

                if (!left.empty() && !right.empty()) {
                    // Load left
                    if (std::isdigit(left[0]))
                        chunk.emit_number(std::stod(left));
                    else {
                        uint16_t li = chunk.add_name(left);
                        chunk.emit(OpCode::LOAD, li);
                    }

                    // Load right
                    if (std::isdigit(right[0]))
                        chunk.emit_number(std::stod(right));
                    else {
                        uint16_t ri = chunk.add_name(right);
                        chunk.emit(OpCode::LOAD, ri);
                    }

                    switch (c) {
                        case '+': chunk.emit(OpCode::ADD); break;
                        case '-': chunk.emit(OpCode::SUB); break;
                        case '*': chunk.emit(OpCode::MUL); break;
                        case '/': chunk.emit(OpCode::DIV); break;
                    }
                    found_op = true;
                    break;
                }
            }
        }

        if (!found_op) {
            // Variable lookup
            uint16_t vi = chunk.add_name(line);
            chunk.emit(OpCode::LOAD, vi);
        }
    }

    chunk.emit(OpCode::PRINT);
    vm.execute(chunk);
}

int main(int argc, char* argv[]) {
    // State file: ~/.tohum/state.bin (persistent across sessions)
    std::filesystem::path home;
#ifdef _WIN32
    const char* userprofile = std::getenv("USERPROFILE");
    if (userprofile) home = userprofile;
#else
    const char* home_env = std::getenv("HOME");
    if (home_env) home = home_env;
#endif

    std::filesystem::path state_dir = home / ".tohum";
    std::filesystem::create_directories(state_dir);
    std::filesystem::path state_file = state_dir / "state.bin";

    VM vm(state_file);

    print_welcome(vm);

    std::string line;
    while (true) {
        std::cout << "tohum > ";
        if (!std::getline(std::cin, line)) {
            std::cout << "\n";
            break; // EOF
        }

        line = trim(line);
        if (line.empty()) continue;
        if (line == "exit" || line == "quit") break;

        try {
            execute_line(vm, line);
        } catch (const std::exception& e) {
            std::cerr << "  error: " << e.what() << "\n";
        }
    }

    // Auto-save on exit
    if (vm.persist()) {
        std::cout << "  (state saved)\n";
    }

    return 0;
}

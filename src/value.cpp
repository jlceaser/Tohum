#include "tohum/value.hpp"

#include <algorithm>
#include <ctime>
#include <iomanip>
#include <sstream>

namespace tohum {

std::string Value::display() const {
    if (is_forgotten()) return "<forgotten>";
    if (is_nil()) return "nil";

    const auto& d = data();
    std::ostringstream out;

    if (std::holds_alternative<double>(d)) {
        double n = std::get<double>(d);
        // Clean integer display
        if (n == static_cast<int64_t>(n) && std::abs(n) < 1e15) {
            out << static_cast<int64_t>(n);
        } else {
            out << n;
        }
    } else if (std::holds_alternative<bool>(d)) {
        out << (std::get<bool>(d) ? "true" : "false");
    } else if (std::holds_alternative<std::string>(d)) {
        out << "\"" << std::get<std::string>(d) << "\"";
    }

    // Show uncertainty if not certain
    if (!is_certain()) {
        if (!is_certain()) {
            out << " @ " << std::fixed << std::setprecision(2) << confidence();
        }
    }

    // Show approximate prefix
    if (!is_certain()) {
        return "~" + out.str();
    }

    return out.str();
}

Confidence propagate_confidence(Confidence a, Confidence b) {
    // Conservative: take the minimum confidence
    // If either input is uncertain, the output is at least as uncertain
    return std::min(a, b);
}

} // namespace tohum

#pragma once

#include <chrono>
#include <cmath>
#include <string>
#include <variant>
#include <vector>

namespace tohum {

// Confidence level: 0.0 = unknown, 1.0 = certain
using Confidence = double;

constexpr Confidence CERTAIN = 1.0;
constexpr Confidence UNKNOWN = 0.0;
constexpr Confidence DEFAULT_THRESHOLD = 0.5;

// A point in a value's timeline
struct TimePoint {
    std::chrono::system_clock::time_point timestamp;
    std::string source; // what caused this value to exist
};

// The raw data a value can hold
using RawValue = std::variant<
    std::monostate, // nil
    double,         // number
    bool,           // boolean
    std::string     // text
>;

// A single moment in a value's history
struct ValueSnapshot {
    RawValue data;
    Confidence confidence;
    TimePoint when;
};

// A temporal value — the core type of Tohum
// This is not just a value. It's a value with a past.
class Value {
public:
    // Create a certain value
    static Value certain(RawValue data, std::string source = "direct") {
        Value v;
        v.push(std::move(data), CERTAIN, std::move(source));
        return v;
    }

    // Create an approximate value
    static Value approximate(RawValue data, Confidence conf, std::string source = "direct") {
        Value v;
        v.push(std::move(data), conf, std::move(source));
        return v;
    }

    // Create nil
    static Value nil() {
        Value v;
        v.push(std::monostate{}, CERTAIN, "nil");
        return v;
    }

    // Get current state
    const ValueSnapshot& current() const { return timeline_.back(); }
    RawValue data() const { return timeline_.back().data; }
    Confidence confidence() const { return timeline_.back().confidence; }
    bool is_certain() const { return confidence() >= 1.0 - 1e-9; }

    // Is this value "truthy" at a given threshold?
    bool truthy(Confidence threshold = DEFAULT_THRESHOLD) const {
        if (confidence() < threshold) return false;
        const auto& d = data();
        if (std::holds_alternative<std::monostate>(d)) return false;
        if (std::holds_alternative<bool>(d)) return std::get<bool>(d);
        if (std::holds_alternative<double>(d)) return std::get<double>(d) != 0.0;
        if (std::holds_alternative<std::string>(d)) return !std::get<std::string>(d).empty();
        return false;
    }

    // Timeline access
    const std::vector<ValueSnapshot>& history() const { return timeline_; }
    std::size_t history_length() const { return timeline_.size(); }

    // Mutate: add a new point to the timeline (not replace!)
    void push(RawValue data, Confidence conf, std::string source) {
        timeline_.push_back(ValueSnapshot{
            .data = std::move(data),
            .confidence = conf,
            .when = TimePoint{
                .timestamp = std::chrono::system_clock::now(),
                .source = std::move(source),
            },
        });
    }

    // Active forgetting — mark the value as forgotten but keep a trace
    void forget() {
        push(std::monostate{}, CERTAIN, "forgotten");
        forgotten_ = true;
    }

    bool is_forgotten() const { return forgotten_; }
    bool is_nil() const { return std::holds_alternative<std::monostate>(data()); }

    // Get as number (for arithmetic)
    double as_number() const {
        if (std::holds_alternative<double>(data())) return std::get<double>(data());
        return 0.0;
    }

    // Get as string (for display)
    std::string display() const;

private:
    std::vector<ValueSnapshot> timeline_;
    bool forgotten_ = false;
};

// Uncertainty arithmetic
// When you add two uncertain values, the result's confidence
// is the minimum of both (conservative propagation)
Confidence propagate_confidence(Confidence a, Confidence b);

} // namespace tohum

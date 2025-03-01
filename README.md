# Evaluator

Evaluator is a Swift library designed to parse and evaluate expressions from strings. Initially, I used [Expression](https://github.com/nicklockwood/Expression), but since it was no longer maintained and lacked short-circuit evaluation, I decided to create my own solution. Evaluator also provides better type safety compared to the loosely-typed `Any` return values in Expression.

## Features
- Supports arithmetic, logical, and bitwise operations
- Short-circuit evaluation for logical expressions
- Variable and function resolution via closures
- Custom types support via conversion protocols
- Strongly typed evaluation with generics
- Cross-platform compatibility (no dependencies)
- Package Manager (SPM) support
- Unit tests included

## Installation
Evaluator is available via Swift Package Manager (SPM). To add it to your project, include the following in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/Evaluator.git", from: "1.0.0")
]
```

## Usage

### Basic Expressions

```swift
let result: Int = try ExpressionEvaluator.evaluate(expression: "2 + 3 * 4")
print(result) // 14
```

### Using Variables

```swift
let result: Bool = try ExpressionEvaluator.evaluate(
    expression: "$age >= 18",
    variables: { name in
        switch name {
        case "$age": return 21
        default: throw ExpressionError.variableNotFound(name)
        }
    }
)
print(result) // true
```

### Using Functions

```swift
let result: Double = try ExpressionEvaluator.evaluate(
    expression: "max(3, 5, 10)",
    functions: { name, args in
        switch name {
        case "max":
            return args.compactMap { $0 as? Double }.max() ?? 0
        default: throw ExpressionError.functionNotFound(name)
        }
    }
)
print(result) // 10
```

### Short-Circuit Evaluation

```swift
let result: Bool = try ExpressionEvaluator.evaluate(
    expression: "$a > 0 && $b == 1",
    variables: { name in
        switch name {
        case "$a": return -1
        case "$b": throw ExpressionError.variableNotFound(name) // This won't be evaluated
        default: throw ExpressionError.variableNotFound(name)
        }
    }
)
print(result) // false (without evaluating $b)
```

### Custom Types Support
Evaluator allows custom types to be used in expressions by implementing conversion protocols.

#### Example: Custom Struct with Protocol Implementation

```swift
struct IntWrapper: EvaluatorIntConvertible {
    let value: Int
    func convertToInt() throws -> Int { return value }
}
```

Now, `IntWrapper` can be used in expressions:

```swift
let result: Bool = try ExpressionEvaluator.evaluate(
    expression: "$wrapped > 10",
    variables: { name in
        switch name {
        case "$wrapped": return IntWrapper(value: 15)
        default: throw ExpressionError.variableNotFound(name)
        }
    }
)
print(result) // true
```

### Custom Comparators
By default, Evaluator can compare numbers, booleans, and strings. However, for custom types, you can define a custom comparator.

#### Example: Money Comparison

```swift
struct Money {
    let amount: Double
    let currency: String
}

let comparator: ExpressionEvaluator.ComparatorResolver = { lhs, rhs, op in
    if let lhs = lhs as? Money, let rhs = rhs as? Money, lhs.currency == rhs.currency {
        return op.compare(lhs: lhs.amount, rhs: rhs.amount)
    }
    throw ExpressionError.typeMismatch("Cannot compare \(type(of: lhs)) with \(type(of: rhs))")
}
```

Usage:

```swift
let result: Bool = try ExpressionEvaluator.evaluate(
    expression: "$wallet1 > $wallet2",
    variables: { name in
        switch name {
        case "$wallet1": return Money(amount: 50, currency: "USD")
        case "$wallet2": return Money(amount: 30, currency: "USD")
        default: throw ExpressionError.variableNotFound(name)
        }
    },
    comparator: comparator
)
print(result) // true
```

## Supported Return Types
Evaluator determines the return type at runtime based on the generic type parameter `T`. It supports:
- `Int`, `Int8`, `Int16`, `Int32`, `Int64`
- `UInt8`, `UInt16`, `UInt32`, `UInt64`
- `Double`, `Float`
- `Bool`
- `String`

If a custom type is used, Evaluator attempts to convert it using `EvaluatorIntConvertible`, `EvaluatorDoubleConvertible`, `EvaluatorStringConvertible`, or `EvaluatorBoolConvertible`.

## License
Evaluator is available under a permissive license. Users can modify and use it in both open and closed-source projects, but redistribution of the library itself for commercial purposes is not allowed.

## Contributions
Suggestions are welcome on a case-by-case basis. Feel free to open an issue or submit a feature request.

---

Evaluator is designed to be lightweight, flexible, and robust, providing a powerful way to evaluate expressions dynamically in Swift applications. 🚀

# Evaluator

## Overview
Evaluator is a Swift library that allows parsing and evaluating expressions provided as strings. It was initially inspired by [Expression](https://github.com/nicklockwood/Expression), a library that was incredibly useful but lacked support for short-circuit operations, which was a critical requirement for my use case. Additionally, I wanted more robust type handling instead of relying heavily on `Any`.

Evaluator is cross-platform and has **no dependencies**, making it lightweight and easy to integrate into any Swift project.

## Features
- Supports **mathematical operations** (`+`, `-`, `*`, `/`, `%`)
- Supports **logical operations** (`&&`, `||`, `!`)
- Supports **comparison operations** (`==`, `!=`, `<`, `<=`, `>`, `>=`)
- Supports **bitwise operations** (`&`, `|`)
- Supports **custom variables** prefixed with `#` or `$`, which accept `_` and `.`
- Supports **custom functions** with dynamic arguments
- Supports **short-circuit evaluation** for logical operations
- Supports **arrays** within variables
- Provides **strong type conversion** using custom Swift protocols
- Works with **custom structs and classes** via protocol conformance

## Installation
Evaluator is available through Swift Package Manager (SPM). To install it, add the following to your `Package.swift`:

```swift
.package(url: "https://github.com/jaeggerr/evaluator.git", from: "1.1.2")
```

Or, if using Xcode, go to **File > Swift Packages > Add Package Dependency** and enter the repository URL.

## Usage

### Basic Expressions
Here are some examples of expressions that Evaluator can handle:

```swift
try ExpressionEvaluator.evaluate(expression: "5 + 3 * 2") // Returns 11
try ExpressionEvaluator.evaluate(expression: "(10 - 4) / 2") // Returns 3.0
try ExpressionEvaluator.evaluate(expression: "true && false") // Returns false
try ExpressionEvaluator.evaluate(expression: "5 > 3 && 10 < 20") // Returns true
```

### Variables
Variables must be prefixed with `#` or `$`. They support underscores (`_`) and dots (`.`) to allow structured names.

```swift
let result = try ExpressionEvaluator.evaluate(expression: "$my_var + 10", variables: { name in
    switch name {
    case "$my_var": return 5
    default: throw ExpressionError.variableNotFound(name)
    }
})
// result == 15
```

#### Using Dotted Notation
```swift
let result = try ExpressionEvaluator.evaluate(expression: "#user.score * 2", variables: { name in
    switch name {
    case "#user.score": return 10
    default: throw ExpressionError.variableNotFound(name)
    }
})
// result == 20
```

### Arrays
Evaluator supports **arrays in variables**, allowing indexed access.

```swift
let result = try ExpressionEvaluator.evaluate(expression: "#values[2] + 1", variables: { name in
    switch name {
    case "#values": return [10, 20, 30, 40]
    default: throw ExpressionError.variableNotFound(name)
    }
})
// result == 31
```

## Supported Functions
Evaluator provides a set of built-in mathematical functions, which can be used in expressions:

| Function  | Description | Example |
|-----------|------------|---------|
| `sqrt(x)`  | Square root | `sqrt(4) = 2.0` |
| `floor(x)` | Rounds down to the nearest integer | `floor(3.7) = 3.0` |
| `ceil(x)`  | Rounds up to the nearest integer | `ceil(3.2) = 4.0` |
| `round(x)` | Rounds to the nearest integer | `round(3.5) = 4.0` |
| `cos(x)`   | Cosine (radians) | `cos(0) = 1.0` |
| `acos(x)`  | Arc cosine | `acos(1) = 0.0` |
| `sin(x)`   | Sine (radians) | `sin(0) = 0.0` |
| `asin(x)`  | Arc sine | `asin(0) = 0.0` |
| `tan(x)`   | Tangent (radians) | `tan(0) = 0.0` |
| `atan(x)`  | Arc tangent | `atan(1) = π/4` |
| `log(x)`   | Natural logarithm | `log(e) = 1.0` |
| `abs(x)`   | Absolute value | `abs(-5) = 5.0` |
| `pow(x, y)` | Power function | `pow(2, 3) = 8.0` |
| `atan2(y, x)` | Two-argument arc tangent | `atan2(1, 1) = π/4` |
| `max(a, b, ...)` | Maximum value | `max(3, 5, 2) = 5.0` |
| `min(a, b, ...)` | Minimum value | `min(3, 5, 2) = 2.0` |

### Overriding Built-in Functions
You can override any built-in function by defining a custom function with the same name. Custom functions take precedence over built-in functions.

```swift
let customFunctions: ExpressionEvaluator.FunctionResolver = { name, args in
    switch name {
    case "sqrt":
        return "Overridden sqrt function!"
    default:
        throw ExpressionError.functionNotFound(name)
    }
}

let result = try ExpressionEvaluator.evaluate(expression: "sqrt(4)", functions: customFunctions)
print(result) // "Overridden sqrt function!"
```

## Custom Functions
Evaluator allows defining custom functions that can be called within an expression.

```swift
let result = try ExpressionEvaluator.evaluate(expression: "sum(1, 2, 3)", functions: { name, args in
    switch name {
    case "sum": return args.reduce(0, { ($0 as! Int) + ($1 as! Int) })
    default: throw ExpressionError.functionNotFound(name)
    }
})
// result == 6
```

## Type Conversion
Evaluator supports **custom types** via protocol conformance. If an unknown type is encountered, it tries to convert it into a suitable type.

### Custom Struct Example
If you have a custom struct `IntWrapper`, you can make it compatible by conforming to `EvaluatorIntConvertible`:

```swift
struct IntWrapper: EvaluatorIntConvertible {
    let value: Int
    func convertToInt() throws -> Int {
        return value
    }
}
```

Then, use it in an expression:

```swift
let result = try ExpressionEvaluator.evaluate(expression: "$wrapped + 2", variables: { name in
    switch name {
    case "$wrapped": return IntWrapper(value: 8)
    default: throw ExpressionError.variableNotFound(name)
    }
})
// result == 10
```

## Generic Return Type Handling
The return type of `evaluate` is determined by the generic parameter `T`.

```swift
let intResult: Int = try ExpressionEvaluator.evaluate(expression: "5 + 2") // Returns Int
let doubleResult: Double = try ExpressionEvaluator.evaluate(expression: "5 / 2") // Returns Double
let boolResult: Bool = try ExpressionEvaluator.evaluate(expression: "5 > 2") // Returns Bool
```

Supported return types:
- `Int`, `Int8`, `Int16`, `Int32`, `Int64`
- `UInt8`, `UInt16`, `UInt32`, `UInt64`
- `Double`, `Float`
- `Bool`
- `String`

## Custom Comparators
Evaluator allows defining **custom comparison behavior** via the `ComparatorResolver`. This is useful for handling user-defined types.

### Example: Comparing Custom Structs
```swift
struct CustomObject {
    let score: Int
}

let comparator: ExpressionEvaluator.ComparatorResolver = { lhs, rhs, op in
    guard let lhsObj = lhs as? CustomObject, let rhsObj = rhs as? CustomObject else {
        throw ExpressionError.typeMismatch("Cannot compare these types")
    }
    return op.compare(lhs: lhsObj.score, rhs: rhsObj.score)
}
```

Then, pass it into `evaluate`:

```swift
let result = try ExpressionEvaluator.evaluate(expression: "$obj1 > $obj2", variables: { name in
    switch name {
    case "$obj1": return CustomObject(score: 50)
    case "$obj2": return CustomObject(score: 30)
    default: throw ExpressionError.variableNotFound(name)
    }
}, comparator: comparator)
// result == true
```

## Function Argument Helper
A helper struct `ArgumentsHelper` has been added to simplify function argument parsing. This helps enforce correct argument types and arities when defining custom functions.

### Usage
```swift
let functions: ExpressionEvaluator.FunctionResolver = {
    switch $0 {
    case "multiply":
        let argsHelper = ArgumentsHelper($1)
        let a: Double = try argsHelper.get(0)
        let b: Double = try argsHelper.get(1)
        return a * b
    default: throw ExpressionError.functionNotFound($0)
    }
}
let result: Double = try ExpressionEvaluator.evaluate(expression: "multiply(3, 4)", functions: functions)
print(result) // Output: 12.0
```

### Features of `ArgumentsHelper`
- Ensures correct number of arguments with `ensureArity()`
- Retrieves arguments safely with type checks
- Supports `Double`, `Int`, `String`, `Bool`, and generic types

## License
This library is licensed under a standard open-source license that allows modifications and closed-source usage but does not permit reselling the library.

## Contributions
Contributions and suggestions are welcome on a case-by-case basis.

## Unit Tests
Unit tests are included to ensure correctness and reliability.

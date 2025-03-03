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
.package(url: "https://github.com/jaeggerr/evaluator.git", from: "1.1.1")
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

## License
This library is licensed under a standard open-source license that allows modifications and closed-source usage but does not permit reselling the library.

## Contributions
Contributions and suggestions are welcome on a case-by-case basis.

## Unit Tests
Unit tests are included to ensure correctness and reliability.

//
//  EvaulatorTests.swift
//  ios-tools
//
//  Created by jaeggerr on 28/02/2025.
//

import Evaluator
import Foundation
import XCTest

class ExpressionEvaluatorTests: XCTestCase {
    // MARK: - Helpers

    func testArithmeticOperations() throws {
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "1 + 2 * 3"), 7)
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "1 + 2 * 3"), 7.0)
    }

    func testDivideInt() throws {
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "3 / 2"), 1.5)
    }

    func testLogicalOperations() throws {
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "true && false"), false)
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "true || false"), true)
    }

    func testBitwiseOperations() throws {
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "5 & 3"), 1)
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "5 | 3"), 7)
    }

    func testVariableResolution() throws {
        let variables: ExpressionEvaluator.VariableResolver = {
            switch $0 {
            case "#int": return 5
            case "#double": return 3.5
            case "$str": return "hello"
            case "#bool": return true
            case "#my_var": return 777
            case "#a.b": return 42
            case "$0": return 88
            default: throw ExpressionError.variableNotFound($0)
            }
        }
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "#int + 2", variables: variables), 7)
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "#int + 2.0", variables: variables), 7)
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "#int + #double", variables: variables), 8.5)
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "$str + ' world'", variables: variables), "hello world")
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "#bool || false", variables: variables), true)
        XCTAssertThrowsError(try ExpressionEvaluator.evaluate(expression: "#unknown") as Int)
        XCTAssertThrowsError(try ExpressionEvaluator.evaluate(expression: "unknown") as Int)
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "#my_var", variables: variables), 777)
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "#a.b", variables: variables), 42)
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "$0", variables: variables), 88)
    }

    func testFunctionResolution() throws {
        let evaluator: Double = try ExpressionEvaluator.evaluate(expression: "sum(1, 2, 3)", functions: { name, args in
            if
                name ==
                "sum"
            {
                return try args
                    .reduce(
                        0)
                {
                    try ($0 as! EvaluatorDoubleConvertible).convertToDouble() + ($1 as! EvaluatorDoubleConvertible)
                        .convertToDouble()
                }
            }
            throw ExpressionError.functionNotFound(name)
        })
        XCTAssertEqual(evaluator, 6.0)
    }

    func testShortCircuitLogicalEvaluation() throws {
        let evaluator: Bool = try ExpressionEvaluator.evaluate(expression: "false && #neverEvaluated")
        XCTAssertEqual(evaluator, false)
    }

    func testInvalidExpression() {
        XCTAssertThrowsError(try ExpressionEvaluator.evaluate(expression: "5 +") as Int)
    }

    func testModulo() {
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "10 % 3"), 1)
    }

    func testBasicArithmetic() throws {
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "2 + 3 * 4"), 14)
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "(2 + 3) * 4"), 20)
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "10 / 2"), 5)
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "5.5 - 2.3"), 3.2)
    }

    // MARK: - Short-Circuit Evaluation

    func testShortCircuitAnd() throws {
        XCTAssertFalse(try ExpressionEvaluator.evaluate(
            expression: "#a && #b",
            variables: {
                if $0 == "#b" { return true }
                if $0 == "#a" { return false }
                throw ExpressionError.variableNotFound($0)
            }
        ))
        XCTAssertTrue(try ExpressionEvaluator.evaluate(
            expression: "#a && #b",
            variables: {
                if $0 == "#b" { return true }
                if $0 == "#a" { return true }
                throw ExpressionError.variableNotFound($0)
            }
        ))
    }

    func testShortCircuitOr() throws {
        XCTAssertTrue(try ExpressionEvaluator.evaluate(
            expression: "#a || #b",
            variables: {
                if $0 == "#b" { return true }
                if $0 == "#a" { return false }
                throw ExpressionError.variableNotFound($0)
            }
        ))
        XCTAssertFalse(try ExpressionEvaluator.evaluate(
            expression: "#a || #b",
            variables: {
                if $0 == "#b" { return false }
                if $0 == "#a" { return false }
                throw ExpressionError.variableNotFound($0)
            }
        ))
    }

    // MARK: - Comparison Operators

    func testComparisons() throws {
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "5 > 3"), true)
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "5.5 <= 5.5"), true)
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "'abc' < 'def'"), true)
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "true == true"), true)
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "10 != 5"), true)
    }

    // MARK: - Type Mismatch

    func testTypeMismatchErrors() throws {
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "'hello' + 5"), "hello5")
        XCTAssertThrowsError(try ExpressionEvaluator.evaluate(expression: "true + false") as Bool)
        XCTAssertThrowsError(try ExpressionEvaluator.evaluate(expression: "5 && 'test'") as Double)
        XCTAssertThrowsError(try ExpressionEvaluator.evaluate(expression: "10.5 & 3") as Double)
        XCTAssertThrowsError(try ExpressionEvaluator.evaluate(expression: "'a' > 5") as Bool)
    }

    // MARK: - Custom Functions

    func testCustomFunctions() throws {
        let functions: ExpressionEvaluator.FunctionResolver = {
            switch $0 {
            case "sum":
                return $1.compactMap { $0 as? Double }.reduce(0, +)
            case "concat":
                return $1.map { String(describing: $0) }.joined()
            default:
                throw ExpressionError.functionNotFound($0)
            }
        }

        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "sum(1, 2, 3)", functions: functions), 6)
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "concat('a', 5, true)", functions: functions), "a5.0true")
    }

    // MARK: - Edge Cases

    func testEdgeCases() throws {
        // Division par zéro
        XCTAssertThrowsError(try ExpressionEvaluator.evaluate(expression: "5 / 0") as Int)

        // Variables complexes
        let variables: ExpressionEvaluator.VariableResolver = {
            if $0 == "#a.b.c" { return 42 }
            throw ExpressionError.variableNotFound($0)
        }
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "#a.b.c", variables: variables), 42)

        // Empty expression
        XCTAssertThrowsError(try ExpressionEvaluator.evaluate(expression: "") as String)
    }

    // MARK: - Error Propagation

    func testErrorPropagation() throws {
        XCTAssertThrowsError(
            try ExpressionEvaluator.evaluate(
                expression: "#test",
                variables: { _ in
                    throw NSError(domain: "CustomError", code: 42)
                }
            ) as Int) { error in
                XCTAssertNotNil(error)
            }
    }

    // MARK: Complex operations

    func testComplexExpression() throws {
        XCTAssertTrue(
            try ExpressionEvaluator
                .evaluate(expression: "((2 + 3) * (4 - 1) / 2 >= 5) && ((8 / 2 == 4)) || ((3 & 1) == 1)"))
    }

    func testCustomComparison() throws {
        struct IntWrapper {
            var value: Int
        }
        let comparator: ExpressionEvaluator.ComparatorResolver = { a, b, opt in
            guard let a = a as? IntWrapper, let b = b as? IntWrapper else {
                throw ExpressionError.invalidOperation("Invalid operands types for comparison.")
            }
            switch opt {
            case .equal: return a.value == b.value
            case .greaterThan: return a.value > b.value
            case .greaterThanOrEqual: return a.value >= b.value
            case .lessThan: return a.value < b.value
            case .lessThanOrEqual: return a.value <= b.value
            }
        }
        XCTAssertTrue(try ExpressionEvaluator.evaluate(expression: "$val_1 < $val_2", variables: {
            switch $0 {
            case "$val_1": return IntWrapper(value: 1)
            case "$val_2": return IntWrapper(value: 2)
            default: throw ExpressionError.variableNotFound($0)
            }
        }, comparator: comparator))
        XCTAssertTrue(try ExpressionEvaluator.evaluate(expression: "$val_1 == $val_2", variables: {
            switch $0 {
            case "$val_1": return IntWrapper(value: 1)
            case "$val_2": return IntWrapper(value: 1)
            default: throw ExpressionError.variableNotFound($0)
            }
        }, comparator: comparator))
    }

    func testNotOperator() throws {
        XCTAssertFalse(try ExpressionEvaluator.evaluate(expression: "!true"))
        XCTAssertTrue(try ExpressionEvaluator.evaluate(expression: "!false"))
        XCTAssertFalse(try ExpressionEvaluator.evaluate(expression: "!$my_var", variables: {
            switch $0 {
            case "$my_var": return true
            default: throw ExpressionError.variableNotFound($0)
            }
        }))
        XCTAssertFalse(try ExpressionEvaluator.evaluate(expression: "!function()", functions: { name, _ in
            switch name {
            case "function": return true
            default: throw ExpressionError.functionNotFound(name)
            }
        }))
    }

    func testArray() throws {
        XCTAssertThrowsError(try ExpressionEvaluator.evaluate(expression: "$my_var[0]") as Double)
        XCTAssertThrowsError(try ExpressionEvaluator.evaluate(expression: "$my_var[0]", variables: {
            switch $0 {
            case "$my_var": return 6.0
            default: throw ExpressionError.variableNotFound($0)
            }
        }) as Double)
        XCTAssertThrowsError(try ExpressionEvaluator.evaluate(expression: "$my_var[2]", variables: {
            switch $0 {
            case "$my_var": return 6.0
            default: throw ExpressionError.variableNotFound($0)
            }
        }) as Double)
        XCTAssertThrowsError(try ExpressionEvaluator.evaluate(expression: "$my_var[3]", variables: {
            switch $0 {
            case "$my_var": return [1]
            default: throw ExpressionError.variableNotFound($0)
            }
        }) as Double)
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "$my_var[1]", variables: {
            switch $0 {
            case "$my_var": return [1, 2]
            default: throw ExpressionError.variableNotFound($0)
            }
        }), 2)
    }

    func testNegative() {
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "$my_var", variables: {
            switch $0 {
            case "$my_var": return -24
            default: throw ExpressionError.variableNotFound($0)
            }
        }), -24)

        XCTAssertTrue(try ExpressionEvaluator.evaluate(expression: "$0 >= -70", variables: {
            switch $0 {
            case "$0": return -24
            default: throw ExpressionError.variableNotFound($0)
            }
        }))
    }

    func testBooleanResult() throws {
        XCTAssertTrue(try ExpressionEvaluator.evaluate(expression: "7 > 2"))
    }

    func testCustomFunction() {
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "$0 + 's ~ ' + dateTime($0)", variables: {
            switch $0 {
            case "$0": return 12346
            default: throw ExpressionError.variableNotFound($0)
            }
        }, functions: { name, args in
            switch name {
            case "dateTime":
                try ExpressionEvaluator.ensureArity(args, 1)
                let interval: TimeInterval = .init(try (args[0] as! EvaluatorDoubleConvertible).convertToDouble())
                let formatter = DateComponentsFormatter()
                formatter.calendar = Calendar(identifier: .gregorian)
                formatter.calendar!.locale = Locale(identifier: "en_US")
                formatter.allowedUnits = [.day, .hour, .minute, .second]
                formatter.unitsStyle = .abbreviated
                return formatter.string(from: interval) ?? "\(interval)s"
            default: throw ExpressionError.functionNotFound(name)
            }
        }), "12346s ~ 3h 25m 46s")
    }

    // MARK: - Nested Expressions

    func testNestedExpressions() throws {
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "((2 + 3) * (4 - 1)) / 2"), 7.5)
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "(5 + (3 * 2) - 4) / 2"), 3.5)
    }

    // MARK: - Edge Case Booleans

    func testBooleanEdgeCases() throws {
        XCTAssertTrue(try ExpressionEvaluator.evaluate(expression: "!false"))
        XCTAssertFalse(try ExpressionEvaluator.evaluate(expression: "!true"))
        XCTAssertTrue(try ExpressionEvaluator.evaluate(expression: "!!true"))
        XCTAssertFalse(try ExpressionEvaluator.evaluate(expression: "!!false"))
    }

    // MARK: - Function Evaluation with Complex Types

    func testFunctionWithCustomType() throws {
        struct IntWrapper: EvaluatorIntConvertible {
            let value: Int
            func convertToInt() throws -> Int { value }
        }

        let functions: ExpressionEvaluator.FunctionResolver = { name, args in
            switch name {
            case "doubleValue":
                try ExpressionEvaluator.ensureArity(args, 1)
                if let wrapped = args[0] as? IntWrapper {
                    return wrapped.value * 2
                }
                throw ExpressionError.invalidOperation("Invalid argument type")
            default:
                throw ExpressionError.functionNotFound(name)
            }
        }

        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "doubleValue($val)", variables: {
            switch $0 {
            case "$val": return IntWrapper(value: 10)
            default: throw ExpressionError.variableNotFound($0)
            }
        }, functions: functions), 20)
    }

    // MARK: - Complex Comparisons

    func testComplexComparisons() throws {
        XCTAssertTrue(try ExpressionEvaluator.evaluate(expression: "(5 > 3) && (10 < 20)"))
        XCTAssertFalse(try ExpressionEvaluator.evaluate(expression: "(5 == 5) && (3 > 4)"))
        XCTAssertTrue(try ExpressionEvaluator.evaluate(expression: "('abc' != 'def') && (10 <= 10)"))
    }

    // MARK: - Mixed Type Operations

    func testMixedTypeOperations() throws {
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "'Number: ' + 42"), "Number: 42")
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "5.5 + 2"), 7.5)
        XCTAssertThrowsError(try ExpressionEvaluator.evaluate(expression: "true + 5") as Int)
    }

    // MARK: - Short-Circuit Edge Cases

    func testShortCircuitEdgeCases() throws {
        XCTAssertFalse(try ExpressionEvaluator.evaluate(expression: "false && $undefinedVariable"))
        XCTAssertTrue(try ExpressionEvaluator.evaluate(expression: "true || $undefinedVariable"))
    }

    // MARK: - Array Access Tests

    func testArrayAccess() throws {
        let variables: ExpressionEvaluator.VariableResolver = {
            if $0 == "$array" { return [10, 20, 30] }
            throw ExpressionError.variableNotFound($0)
        }

        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "$array[0]", variables: variables), 10)
        XCTAssertEqual(try ExpressionEvaluator.evaluate(expression: "$array[1]", variables: variables), 20)
        XCTAssertThrowsError(try ExpressionEvaluator.evaluate(expression: "$array[5]", variables: variables) as Int)
    }

    // MARK: - Invalid Expressions

    func testInvalidExpressions() throws {
        XCTAssertThrowsError(try ExpressionEvaluator.evaluate(expression: "()") as Int)
        XCTAssertThrowsError(try ExpressionEvaluator.evaluate(expression: "5 + * 3") as Int)
        XCTAssertThrowsError(try ExpressionEvaluator.evaluate(expression: "'hello") as String)
    }
}

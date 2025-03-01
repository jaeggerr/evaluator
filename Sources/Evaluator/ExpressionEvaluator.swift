//
//  ExpressionEvaluator.swift
//  evaluator
//
//  Created by jaeggerr on 01/03/2025.
//

import Foundation

// MARK: - ExpressionError

public enum ExpressionError: Error, Equatable {
    case parseError(String)
    case variableNotFound(String)
    case typeMismatch(String)
    case invalidOperation(String)
    case functionNotFound(String)
    case missingOperand(String)
    case invalidArity(_ requiredArguments: Int)
}

// MARK: - Operator

enum Operator: String, CaseIterable {
    case plus = "+"
    case minus = "-"
    case multiply = "*"
    case divide = "/"
    case modulo = "%"
    case equal = "=="
    case notEqual = "!="
    case or = "||"
    case and = "&&"
    case bitwiseOr = "|"
    case bitwiseAnd = "&"
    case greaterThan = ">"
    case greaterThanOrEqual = ">="
    case lessThan = "<"
    case lessThanOrEqual = "<="
    case not = "!"
}

// MARK: - ComparisonOperator

public enum ComparisonOperator {
    case equal
    case greaterThan
    case greaterThanOrEqual
    case lessThan
    case lessThanOrEqual

    public func compare<T: Comparable>(lhs: T, rhs: T) -> Bool {
        switch self {
        case .equal: return lhs == rhs
        case .greaterThan: return lhs > rhs
        case .greaterThanOrEqual: return lhs >= rhs
        case .lessThan: return lhs < rhs
        case .lessThanOrEqual: return lhs <= rhs
        }
    }
}

// MARK: - ExpressionEvaluator

public struct ExpressionEvaluator {

    // MARK: Public

    public typealias VariableResolver = (String) throws -> Any
    public typealias FunctionResolver = (String, [Any]) throws -> Any
    public typealias ComparatorResolver = (Any, Any, ComparisonOperator) throws -> Bool

    public static func evaluate<T>(
        expression: String,
        variables: @escaping VariableResolver = { throw ExpressionError.variableNotFound($0) },
        functions: @escaping FunctionResolver = { name, _ in throw ExpressionError.functionNotFound(name) },
        comparator: @escaping ComparatorResolver = { a, b, _ in
            throw ExpressionError.invalidOperation("Comparison impossible for type \(type(of: a)) and \(type(of: b))")
        }) throws
        -> T {
        var tokenizer = Tokenizer(input: expression)
        let tokens = try tokenizer.tokenize()
        guard !tokens.isEmpty else {
            throw ExpressionError.parseError("No valid tokens found")
        }
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        let result = try evaluate(node: ast, variables: variables, functions: functions, comparator: comparator)
        if let result = result as? T {
            return result
        } else if T.self == Int.self, let convertible = result as? EvaluatorIntConvertible {
            return try convertible.convertToInt() as! T
        } else if T.self == Int8.self, let convertible = result as? EvaluatorIntConvertible {
            return try Int8(convertible.convertToInt()) as! T
        } else if T.self == Int16.self, let convertible = result as? EvaluatorIntConvertible {
            return try Int16(convertible.convertToInt()) as! T
        } else if T.self == Int32.self, let convertible = result as? EvaluatorIntConvertible {
            return try Int32(convertible.convertToInt()) as! T
        } else if T.self == Int64.self, let convertible = result as? EvaluatorIntConvertible {
            return try Int64(convertible.convertToInt()) as! T
        } else if T.self == UInt8.self, let convertible = result as? EvaluatorIntConvertible {
            return try UInt8(convertible.convertToInt()) as! T
        } else if T.self == UInt16.self, let convertible = result as? EvaluatorIntConvertible {
            return try UInt16(convertible.convertToInt()) as! T
        } else if T.self == UInt32.self, let convertible = result as? EvaluatorIntConvertible {
            return try UInt32(convertible.convertToInt()) as! T
        } else if T.self == UInt64.self, let convertible = result as? EvaluatorIntConvertible {
            return try UInt64(convertible.convertToInt()) as! T
        } else if T.self == Double.self, let convertible = result as? EvaluatorDoubleConvertible {
            return try convertible.convertToDouble() as! T
        } else if T.self == Float.self, let convertible = result as? EvaluatorDoubleConvertible {
            return Float(try convertible.convertToDouble()) as! T
        } else if T.self == Bool.self, let convertible = result as? EvaluatorBoolConvertible {
            return try convertible.convertToBool() as! T
        } else {
            throw ExpressionError.typeMismatch("Expected return type \(T.self) instead of \(type(of: result))")
        }
    }

    public static func ensureArity(_ args: [Any], _ expectedArity: Int) throws(ExpressionError) {
        guard args.count == expectedArity else {
            throw .invalidArity(expectedArity)
        }
    }

    // MARK: Private

    private static func evaluate(
        node: ASTNode,
        variables: VariableResolver,
        functions: FunctionResolver,
        comparator: ComparatorResolver) throws
        -> Any {
        switch node {
        case .unaryOp(let op, let operand):
            let value = try evaluate(node: operand, variables: variables, functions: functions, comparator: comparator)
            switch op {
            case .not:
                guard let boolValue = value as? Bool else {
                    throw ExpressionError.typeMismatch("Operand must be Bool for NOT operator")
                }
                return !boolValue
            default:
                throw ExpressionError.invalidOperation("Unsupported unary operator")
            }
        case .binaryOp(let left, let op, let right):
            return try evaluateBinaryOp(
                left: left,
                op: op,
                right: right,
                variables: variables,
                functions: functions,
                comparator: comparator)

        case .variable(let name):
            return try variables(name)

        case .functionCall(let name, let args):
            let evaluatedArgs = try args
                .map { try evaluate(node: $0, variables: variables, functions: functions, comparator: comparator) }
            return try functions(name, evaluatedArgs)

        case .literal(let value):
            return value

        case .arrayAccess(let variable, let indexNode):
            let array = try variables(variable)
            guard let array = array as? [Any] else {
                throw ExpressionError.typeMismatch("\(variable) is not an array")
            }

            let indexValue = try evaluate(node: indexNode, variables: variables, functions: functions, comparator: comparator)
            guard let index = try (indexValue as? EvaluatorIntConvertible)?.convertToInt() else {
                throw ExpressionError.typeMismatch("Array index must be Int")
            }

            guard array.indices.contains(index) else {
                throw ExpressionError.invalidOperation("Index \(index) out of bounds")
            }

            return array[index]
        }
    }

    private static func evaluateBinaryOp(
        left: ASTNode,
        op: Operator,
        right: ASTNode,
        variables: VariableResolver,
        functions: FunctionResolver,
        comparator: ComparatorResolver) throws
        -> Any {
        switch op {
        case .and:
            let lhs = try evaluate(node: left, variables: variables, functions: functions, comparator: comparator)
            guard let leftBool = lhs as? Bool else {
                throw ExpressionError.typeMismatch("Left operand of && must be Bool")
            }
            if !leftBool { return false }
            let rhs = try evaluate(node: right, variables: variables, functions: functions, comparator: comparator)
            guard let rightBool = rhs as? Bool else {
                throw ExpressionError.typeMismatch("Right operand of && must be Bool")
            }
            return rightBool

        case .or:
            let lhs = try evaluate(node: left, variables: variables, functions: functions, comparator: comparator)
            guard let leftBool = lhs as? Bool else {
                throw ExpressionError.typeMismatch("Left operand of || must be Bool")
            }
            if leftBool { return true }
            let rhs = try evaluate(node: right, variables: variables, functions: functions, comparator: comparator)
            guard let rightBool = rhs as? Bool else {
                throw ExpressionError.typeMismatch("Right operand of || must be Bool")
            }
            return rightBool

        default:
            let lhs = try evaluate(node: left, variables: variables, functions: functions, comparator: comparator)
            let rhs = try evaluate(node: right, variables: variables, functions: functions, comparator: comparator)
            return try applyOperator(op, lhs: lhs, rhs: rhs, comparator: comparator)
        }
    }

    private static func convertToInt(_ value: Any) throws -> Int {
        guard let convertible = value as? EvaluatorIntConvertible else {
            throw ExpressionError.typeMismatch("Non numeric value: \(value)")
        }
        return try convertible.convertToInt()
    }

    private static func convertToDouble(_ value: Any) throws -> Double {
        guard let convertible = value as? EvaluatorDoubleConvertible else {
            throw ExpressionError.typeMismatch("Non numeric value: \(value)")
        }
        return try convertible.convertToDouble()
    }

    private static func applyOperator(_ op: Operator, lhs: Any, rhs: Any, comparator: ComparatorResolver) throws -> Any {
        switch op {
        case .plus:
            // Doubles are prevalent to strings
            if let l = lhs as? EvaluatorDoubleConvertible, let r = rhs as? EvaluatorDoubleConvertible {
                return try l.convertToDouble() + r.convertToDouble()
            } else if let l = lhs as? EvaluatorStringConvertible, let r = rhs as? EvaluatorStringConvertible {
                return try l.convertToString() + r.convertToString()
            } else if type(of: lhs) != type(of: rhs) {
                throw ExpressionError.typeMismatch("Incompatible operands for concatenation")
            } else {
                throw ExpressionError.typeMismatch("Operands must be numeric or string")
            }
        case .minus:
            let lNum = try convertToDouble(lhs)
            let rNum = try convertToDouble(rhs)
            return lNum - rNum

        case .multiply:
            let lNum = try convertToDouble(lhs)
            let rNum = try convertToDouble(rhs)
            return lNum * rNum

        case .divide:
            let lNum = try convertToDouble(lhs)
            let rNum = try convertToDouble(rhs)
            guard rNum != 0 else { throw ExpressionError.invalidOperation("Division by zero") }
            return lNum / rNum

        case .modulo:
            let lNum = try convertToDouble(lhs)
            let rNum = try convertToDouble(rhs)
            return lNum.truncatingRemainder(dividingBy: rNum)

        case .equal:
            return try compare(lhs, rhs, .equal, comparator: comparator)

        case .notEqual:
            return try !compare(lhs, rhs, .equal, comparator: comparator)

        case .greaterThan:
            return try compare(lhs, rhs, .greaterThan, comparator: comparator)

        case .greaterThanOrEqual:
            return try compare(lhs, rhs, .greaterThanOrEqual, comparator: comparator)

        case .lessThan:
            return try compare(lhs, rhs, .lessThan, comparator: comparator)

        case .lessThanOrEqual:
            return try compare(lhs, rhs, .lessThanOrEqual, comparator: comparator)

        case .bitwiseAnd:
            return try convertToInt(lhs) & convertToInt(rhs)
        case .bitwiseOr:
            return try convertToInt(lhs) | convertToInt(rhs)
        default:
            throw ExpressionError.invalidOperation("Unsupported operator: \(op.rawValue)")
        }
    }

    private static func compare(
        _ a: Any,
        _ b: Any,
        _ `operator`: ComparisonOperator,
        comparator: ComparatorResolver) throws
        -> Bool {
        if let aNum = try? convertToDouble(a), let bNum = try? convertToDouble(b) {
            return `operator`.compare(lhs: aNum, rhs: bNum)
        }
        if let aString = a as? String, let bString = b as? String {
            return `operator`.compare(lhs: aString, rhs: bString)
        }
        if let aBool = a as? Bool, let bBool = b as? Bool {
            switch `operator` {
            case .equal: return aBool == bBool
            default: break
            }
        }
        return try comparator(a, b, `operator`)
    }
}

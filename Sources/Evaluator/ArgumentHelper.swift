//
//  ResolvedFunction.swift
//  evaluator
//
//  Created by jaeggerr on 02/03/2025.
//

/// Defines the arity (number of arguments) constraints for function evaluation.
///
/// Used to enforce correct function argument counts when evaluating expressions.
public enum Arity: Equatable {
    /// Specifies that the function must have exactly `n` arguments.
    case exactly(Int)

    /// Specifies that the function must have at least `n` arguments.
    case atLeast(Int)

    /// Specifies that the function must have at most `n` arguments.
    case atMost(Int)
}

/// A helper struct for managing function arguments in the Evaluator library.
/// This struct provides type-safe retrieval of function arguments and ensures
/// that the correct number of arguments is provided.
public struct ArgumentsHelper {
    private let args: [Any]

    /// Initializes an `ArgumentsHelper` instance with the provided arguments.
    ///
    /// - Parameter args: An array of arguments to be processed.
    public init(_ args: [Any]) {
        self.args = args
    }

    /// Ensures that the provided arguments match the required arity.
    ///
    /// - Parameter arity: The expected number of arguments.
    /// - Throws: `ExpressionError.invalidArity` if the arity does not match.
    public func ensureArity(_ arity: Arity) throws {
        switch arity {
        case let .exactly(count):
            if args.count != count { throw ExpressionError.invalidArity(arity) }
        case let .atLeast(count):
            if args.count < count { throw ExpressionError.invalidArity(arity) }
        case let .atMost(count):
            if args.count > count { throw ExpressionError.invalidArity(arity) }
        }
    }

    /// Retrieves an argument as a `Double`, ensuring type safety.
    ///
    /// - Parameter index: The index of the argument.
    /// - Throws: `ExpressionError.typeMismatch` if the argument cannot be converted to `Double`.
    /// - Returns: The argument as a `Double`.
    public func get(_ index: Int) throws -> Double {
        try ensureArity(.atLeast(index + 1))
        guard let arg = args[index] as? EvaluatorDoubleConvertible else {
            throw ExpressionError.typeMismatch("Expected double convertible argument")
        }
        return try arg.convertToDouble()
    }

    /// Retrieves an argument as an `Int`, ensuring type safety.
    ///
    /// - Parameter index: The index of the argument.
    /// - Throws: `ExpressionError.typeMismatch` if the argument cannot be converted to `Int`.
    /// - Returns: The argument as an `Int`.
    public func get(_ index: Int) throws -> Int {
        try ensureArity(.atLeast(index + 1))
        guard let arg = args[index] as? EvaluatorIntConvertible else {
            throw ExpressionError.typeMismatch("Expected int convertible argument")
        }
        return try arg.convertToInt()
    }

    /// Retrieves an argument as a `String`, ensuring type safety.
    ///
    /// - Parameter index: The index of the argument.
    /// - Throws: `ExpressionError.typeMismatch` if the argument cannot be converted to `String`.
    /// - Returns: The argument as a `String`.
    public func get(_ index: Int) throws -> String {
        try ensureArity(.atLeast(index + 1))
        guard let arg = args[index] as? EvaluatorStringConvertible else {
            throw ExpressionError.typeMismatch("Expected string convertible argument")
        }
        return try arg.convertToString()
    }

    /// Retrieves an argument as a `Bool`, ensuring type safety.
    ///
    /// - Parameter index: The index of the argument.
    /// - Throws: `ExpressionError.typeMismatch` if the argument cannot be converted to `Bool`.
    /// - Returns: The argument as a `Bool`.
    public func get(_ index: Int) throws -> Bool {
        try ensureArity(.atLeast(index + 1))
        guard let arg = args[index] as? EvaluatorBoolConvertible else {
            throw ExpressionError.typeMismatch("Expected boolean convertible argument")
        }
        return try arg.convertToBool()
    }

    /// Retrieves an argument as a generic type `T`, ensuring type safety.
    ///
    /// - Parameters:
    ///   - index: The index of the argument.
    ///   - type: The expected type of the argument.
    /// - Throws: `ExpressionError.typeMismatch` if the argument cannot be cast to `T`.
    /// - Returns: The argument as type `T`.
    public func get<T>(_ index: Int, type: T.Type) throws -> T {
        try ensureArity(.atLeast(index + 1))
        guard let arg = args[index] as? T else {
            throw ExpressionError.typeMismatch("Expected argument of type \(type)")
        }
        return arg
    }
}

//
//  ExpressionEvaluator+Functions.swift
//  evaluator
//
//  Created by Cedric on 03/03/2025.
//

import Foundation

public extension ExpressionEvaluator {
    static var libraryFunctions: FunctionResolver {
        return { name, arguments in
            let args = ArgumentsHelper(arguments)
            switch name {
            case "sqrt":
                return sqrt(try args.get(0) as Double)
            case "floor":
                return floor(try args.get(0) as Double)
            case "ceil":
                return ceil(try args.get(0) as Double)
            case "round":
                return round(try args.get(0) as Double)
            case "cos":
                return cos(try args.get(0) as Double)
            case "acos":
                return acos(try args.get(0) as Double)
            case "sin":
                return sin(try args.get(0) as Double)
            case "asin":
                return asin(try args.get(0) as Double)
            case "tan":
                return tan(try args.get(0) as Double)
            case "atan":
                return atan(try args.get(0) as Double)
            case "abs":
                return abs(try args.get(0) as Double)
            case "log":
                return log(try args.get(0) as Double)
            case "pow":
                return pow(try args.get(0) as Double, try args.get(1) as Double)
            case "atan2":
                return atan2(try args.get(0) as Double, try args.get(1) as Double)
            case "max":
                try args.ensureArity(.atLeast(2))
                return try (0 ..< arguments.count).map { try args.get($0) as Double }.max()!
            case "min":
                try args.ensureArity(.atLeast(2))
                return try (0 ..< arguments.count).map { try args.get($0) as Double }.min()!
            default:
                throw ExpressionError.functionNotFound(name)
            }
        }
    }
}

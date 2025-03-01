//
//  Protocols.swift
//  evaluator
//
//  Created by jaeggerr on 01/03/2025.
//

import Foundation

// MARK: - EvaluatorDoubleConvertible

public protocol EvaluatorDoubleConvertible {
    func convertToDouble() throws -> Double
}

// MARK: - EvaluatorIntConvertible

public protocol EvaluatorIntConvertible {
    func convertToInt() throws -> Int
}

// MARK: - EvaluatorStringConvertible

public protocol EvaluatorStringConvertible {
    func convertToString() throws -> String
}

// MARK: - EvaluatorBoolConvertible

public protocol EvaluatorBoolConvertible {
    func convertToBool() throws -> Bool
}

// MARK: - Int + EvaluatorDoubleConvertible, EvaluatorIntConvertible

extension Int: EvaluatorDoubleConvertible, EvaluatorIntConvertible, EvaluatorStringConvertible {
    public func convertToDouble() throws -> Double {
        Double(self)
    }

    public func convertToInt() throws -> Int {
        self
    }

    public func convertToString() throws -> String {
        "\(self)"
    }
}

// MARK: - Double + EvaluatorDoubleConvertible, EvaluatorIntConvertible

extension Double: EvaluatorDoubleConvertible, EvaluatorIntConvertible, EvaluatorStringConvertible {
    public func convertToDouble() -> Double {
        self
    }

    public func convertToInt() throws -> Int {
        if truncatingRemainder(dividingBy: 1) == 0 {
            return Int(self)
        }
        throw ExpressionError.typeMismatch("Double value has decimals")
    }

    public func convertToString() throws -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        return formatter.string(for: self)!
    }
}

// MARK: - String + EvaluatorStringConvertible

extension String: EvaluatorStringConvertible {
    public func convertToString() throws -> String {
        self
    }
}

// MARK: - Bool + EvaluatorBoolConvertible

extension Bool: EvaluatorBoolConvertible {
    public func convertToBool() throws -> Bool {
        self
    }
}

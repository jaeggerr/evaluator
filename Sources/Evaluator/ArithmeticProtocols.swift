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
        // Render whole values without a decimal separator ("2" rather than "2.0"),
        // and keep every significant digit otherwise. Deliberately not using
        // NumberFormatter: its default numberStyle rounds to zero fraction digits
        // and its output is locale dependent.
        if truncatingRemainder(dividingBy: 1) == 0, abs(self) < 1e15 {
            return String(Int(self))
        }
        return "\(self)"
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

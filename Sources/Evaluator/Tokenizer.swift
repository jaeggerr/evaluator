//
//  Tokenizer.swift
//  evaluator
//
//  Created by jaeggerr on 01/03/2025.
//

// MARK: - Token

enum Token: Equatable {
    case number(Double)
    case string(String)
    case boolean(Bool)
    case identifier(String)
    case variable(String)
    case `operator`(Operator)
    case leftParen
    case rightParen
    case comma
    case leftBracket
    case rightBracket
}

extension Token {
    /// Whether this token can end an operand, so that a following '-' is a binary operator.
    var endsOperand: Bool {
        switch self {
        case .number, .string, .boolean, .variable, .rightParen, .rightBracket:
            return true
        case .identifier, .operator, .leftParen, .comma, .leftBracket:
            return false
        }
    }
}

// MARK: - Tokenizer

struct Tokenizer {
    // MARK: Lifecycle

    init(input: String) {
        self.input = input
        index = input.startIndex
    }

    // MARK: Internal

    let input: String
    var index: String.Index

    mutating func tokenize() throws -> [Token] {
        var tokens = [Token]()
        while index < input.endIndex {
            let c = input[index]
            switch c {
            case " ", "\t", "\n":
                advance()
            case "#", "$":
                try tokens.append(parseVariable())
            case "'":
                try tokens.append(.string(parseString()))
            case "0" ... "9":
                try tokens.append(.number(parseNumber()))
            case "(":
                tokens.append(.leftParen)
                advance()
            case ")":
                tokens.append(.rightParen)
                advance()
            case ",":
                tokens.append(.comma)
                advance()
            case "[":
                tokens.append(.leftBracket)
                advance()
            case "]":
                tokens.append(.rightBracket)
                advance()
            // A '-' directly followed by a digit is a negative literal only where an operand is
            // expected; after a value it is the subtraction operator ("5-3" is 5 minus 3).
            case "-" where input.index(after: index) < input.endIndex
                && input[input.index(after: index)].isNumber
                && !(tokens.last?.endsOperand ?? false):
                try tokens.append(.number(parseNumber()))
            default:
                if let op = try parseOperator() {
                    tokens.append(.operator(op))
                } else if c.isLetter || c == "_" {
                    // Read the whole word before deciding: only an exact "true"/"false" is a
                    // boolean, so a function such as truncate() stays one identifier.
                    switch parseIdentifier() {
                    case "true": tokens.append(.boolean(true))
                    case "false": tokens.append(.boolean(false))
                    case let name: tokens.append(.identifier(name))
                    }
                } else {
                    throw ExpressionError.parseError("Unexpected character: \(c)")
                }
            }
        }
        return tokens
    }

    // MARK: Private

    private mutating func parseVariable() throws -> Token {
        let startIndex = index
        advance() // Skip '#' or '$'

        // Ensure variable starts with a letter or '_'
        guard index < input.endIndex, input[index].isAlphanumeric || input[index] == "_" else {
            throw ExpressionError.parseError("Invalid variable name: must start with a letter, a number, or '_'")
        }

        advance()

        // Accept letters, digits, '_', and '.'
        while index < input.endIndex {
            let currentChar = input[index]

            // The first character is already checked above, so a '.' can only be misplaced at the
            // end of the name: it must be followed by another name character ("#a.b", not "#a." or
            // "#a..b").
            if currentChar == "." {
                let next = input.index(after: index)
                guard next < input.endIndex, input[next].isAlphanumeric || input[next] == "_" else {
                    throw ExpressionError.parseError("Invalid variable name: '.' cannot be at the end")
                }
            }

            // Accept valid characters
            if currentChar.isAlphanumeric || currentChar == "_" || currentChar == "." {
                advance()
            } else {
                break
            }
        }

        let variableName = String(input[startIndex ..< index])
        return .variable(variableName)
    }

    private mutating func parseString() throws -> String {
        advance() // Skip opening quote
        var str = ""
        while index < input.endIndex && input[index] != "'" {
            str.append(input[index])
            advance()
        }
        guard index < input.endIndex else {
            throw ExpressionError.parseError("Unterminated string literal")
        }
        advance() // Skip closing quote
        return str
    }

    private mutating func parseNumber() throws -> Double {
        var str = ""

        if input[index] == "-" {
            str.append("-")
            advance()
        }

        while index < input.endIndex, input[index].isNumber || input[index] == "." {
            str.append(input[index])
            advance()
        }

        guard !str.isEmpty, let num = Double(str) else {
            throw ExpressionError.parseError("Invalid number: \(str)")
        }
        return num
    }

    private mutating func parseOperator() throws -> Operator? {
        let multiCharOps = ["==", "!=", "&&", "||", ">=", "<=", "%"]
        for op in multiCharOps {
            if input.hasPrefix(op, startingAt: index) {
                advance(by: op.count)
                return Operator(rawValue: op)
            }
        }
        if let op = Operator(rawValue: String(input[index])) {
            advance()
            return op
        }
        return nil
    }

    private mutating func parseIdentifier() -> String {
        let start = index
        // Same character set as variable names, so a function such as all_passed() is valid.
        while index < input.endIndex, input[index].isAlphanumeric || input[index] == "_" {
            advance()
        }
        return String(input[start ..< index])
    }

    private mutating func advance(by n: Int = 1) {
        index = input.index(index, offsetBy: n, limitedBy: input.endIndex) ?? input.endIndex
    }
}

// MARK: - Extensions

private extension String {
    func hasPrefix(_ prefix: String, startingAt index: String.Index) -> Bool {
        guard let endIndex = self.index(index, offsetBy: prefix.count, limitedBy: endIndex) else {
            return false
        }
        return self[index ..< endIndex] == prefix
    }
}

private extension Character {
    var isAlphanumeric: Bool {
        isLetter || isNumber
    }
}

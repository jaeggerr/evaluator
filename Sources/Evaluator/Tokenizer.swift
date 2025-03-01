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
            case _ where input.hasPrefix("true", startingAt: index):
                try tokens.append(.boolean(parseBoolean()))
            case _ where input.hasPrefix("false", startingAt: index):
                try tokens.append(.boolean(parseBoolean()))
            case "#", "$":
                try tokens.append(parseVariable())
            case "'":
                try tokens.append(.string(parseString()))
            case "0"..."9":
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
            case "-" where input.index(after: index) < input.endIndex && input[input.index(after: index)].isNumber:
                try tokens.append(.number(parseNumber()))
            default:
                if let op = try parseOperator() {
                    tokens.append(.operator(op))
                } else if c.isLetter {
                    tokens.append(.identifier(parseIdentifier()))
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

            // Ensure '.' is not at the beginning or end
            if currentChar == "." {
                if index == startIndex || input.index(after: index) == input.endIndex {
                    throw ExpressionError.parseError("Invalid variable name: '.' cannot be at the beginning or end")
                }
            }

            // Accept valid characters
            if currentChar.isAlphanumeric || currentChar == "_" || currentChar == "." {
                advance()
            } else {
                break
            }
        }

        let variableName = String(input[startIndex..<index])
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

    private mutating func parseBoolean() throws -> Bool {
        if input.hasPrefix("true", startingAt: index) {
            advance(by: 4)
            return true
        } else if input.hasPrefix("false", startingAt: index) {
            advance(by: 5)
            return false
        }
        throw ExpressionError.parseError("Invalid boolean literal")
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
        while index < input.endIndex, input[index].isAlphanumeric {
            advance()
        }
        return String(input[start..<index])
    }

    private mutating func advance(by n: Int = 1) {
        index = input.index(index, offsetBy: n, limitedBy: input.endIndex) ?? input.endIndex
    }
}

// MARK: - Extensions

extension String {
    fileprivate func hasPrefix(_ prefix: String, startingAt index: String.Index) -> Bool {
        guard let endIndex = self.index(index, offsetBy: prefix.count, limitedBy: endIndex) else {
            return false
        }
        return self[index..<endIndex] == prefix
    }
}

extension Character {
    fileprivate var isAlphanumeric: Bool {
        isLetter || isNumber
    }
}

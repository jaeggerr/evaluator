//
//  Parser.swift
//  evaluator
//
//  Created by jaeggerr on 01/03/2025.
//

// MARK: - ASTNode

indirect enum ASTNode {
    case unaryOp(op: Operator, operand: ASTNode)
    case binaryOp(left: ASTNode, op: Operator, right: ASTNode)
    case variable(String)
    case functionCall(name: String, args: [ASTNode])
    case literal(Any)
    case arrayAccess(variable: String, index: ASTNode)
}

// MARK: - Parser

class Parser {
    // MARK: Lifecycle

    init(tokens: [Token]) {
        self.tokens = tokens
    }

    // MARK: Internal

    func parse() throws -> ASTNode {
        guard !tokens.isEmpty else {
            throw ExpressionError.parseError("Empty expression")
        }
        return try parseExpression()
    }

    // MARK: Private

    private let tokens: [Token]
    private var currentIndex = 0

    private func parseExpression() throws -> ASTNode {
        try parseLogicalOr()
    }

    private func parseLogicalOr() throws -> ASTNode {
        var node = try parseLogicalAnd()
        while let token = peek(), case .operator(.or) = token {
            try consume()
            let right = try parseLogicalAnd()
            node = .binaryOp(left: node, op: .or, right: right)
        }
        return node
    }

    private func parseLogicalAnd() throws -> ASTNode {
        var node = try parseEquality()
        while let token = peek(), case .operator(.and) = token {
            try consume()
            let right = try parseEquality()
            node = .binaryOp(left: node, op: .and, right: right)
        }
        return node
    }

    private func parseEquality() throws -> ASTNode {
        var node = try parseComparison()
        while let token = peek(), case let .operator(op) = token, op == .equal || op == .notEqual {
            try consume()
            let right = try parseComparison()
            node = .binaryOp(left: node, op: op, right: right)
        }
        return node
    }

    private func parseComparison() throws -> ASTNode {
        var node = try parseBitwiseOr()
        while
            let token = peek(), case let .operator(op) = token,
            [.greaterThan, .greaterThanOrEqual, .lessThan, .lessThanOrEqual].contains(op)
        {
            try consume()
            let right = try parseBitwiseOr()
            node = .binaryOp(left: node, op: op, right: right)
        }
        return node
    }

    private func parseBitwiseOr() throws -> ASTNode {
        var node = try parseBitwiseAnd()
        while let token = peek(), case .operator(.bitwiseOr) = token {
            try consume()
            let right = try parseBitwiseAnd()
            node = .binaryOp(left: node, op: .bitwiseOr, right: right)
        }
        return node
    }

    private func parseBitwiseAnd() throws -> ASTNode {
        var node = try parseAdditive()
        while let token = peek(), case .operator(.bitwiseAnd) = token {
            try consume()
            let right = try parseAdditive()
            node = .binaryOp(left: node, op: .bitwiseAnd, right: right)
        }
        return node
    }

    private func parseAdditive() throws -> ASTNode {
        var node = try parseMultiplicative()
        while let token = peek(), case let .operator(op) = token, op == .plus || op == .minus {
            try consume()
            let right = try parseMultiplicative()
            node = .binaryOp(left: node, op: op, right: right)
        }
        return node
    }

    private func parseMultiplicative() throws -> ASTNode {
        var node = try parsePrimary()
        while let token = peek(), case let .operator(op) = token, op == .multiply || op == .divide || op == .modulo {
            try consume()
            let right = try parsePrimary()
            node = .binaryOp(left: node, op: op, right: right)
        }
        return node
    }

    private func parsePrimary() throws -> ASTNode {
        let token = try consume()
        switch token {
        case .operator(.not):
            let operand = try parsePrimary()
            return .unaryOp(op: .not, operand: operand)
        case let .number(value):
            return .literal(value)
        case let .string(value):
            return .literal(value)
        case let .boolean(value):
            return .literal(value)
        case let .variable(name):
            if peek() == .leftBracket {
                try consume()
                let index = try parseExpression()
                guard try consume() == .rightBracket else {
                    throw ExpressionError.parseError("Expected ']'")
                }
                return .arrayAccess(variable: name, index: index)
            }
            return .variable(name)
        case let .identifier(name):
            if peek() == .leftParen {
                try consume()
                var args = [ASTNode]()
                while peek() != .rightParen {
                    let arg = try parseExpression()
                    args.append(arg)
                    if peek() == .comma {
                        try consume()
                    }
                }
                try consume()
                return .functionCall(name: name, args: args)
            }
            throw ExpressionError.parseError("Unexpected identifier: \(name)")
        case .leftParen:
            let expr = try parseExpression()
            guard case .rightParen = try consume() else {
                throw ExpressionError.parseError("Expected ')'")
            }
            return expr
        default:
            throw ExpressionError.parseError("Unexpected token: \(token)")
        }
    }

    private func peek() -> Token? {
        guard currentIndex < tokens.count else { return nil }
        return tokens[currentIndex]
    }

    @discardableResult
    private func consume() throws -> Token {
        guard currentIndex < tokens.count else {
            throw ExpressionError.missingOperand("Unexpected end of expression")
        }
        defer { currentIndex += 1 }
        return tokens[currentIndex]
    }
}

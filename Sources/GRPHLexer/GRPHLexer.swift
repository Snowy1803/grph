//
//  GRPHLexer.swift
//  GRPHLexer
//
//  Created by Emil Pedersen on 27/08/2021.
//

import Foundation

public class GRPHLexer {
    
    var lineNumber = 0
    
    public func parseDocument(content: String) -> [Token] {
        let lines = content.components(separatedBy: "\n")
        var tokens: [Token] = []
        tokens.reserveCapacity(lines.count)
        for lineNumber in 0..<lines.count {
            tokens.append(parseLine(lineNumber: lineNumber, content: lines[lineNumber]))
        }
        return tokens
    }
    
    public func parseLine(lineNumber: Int, content: String) -> Token {
        self.lineNumber = lineNumber
        var hierarchy = [Token(lineNumber: lineNumber, lineOffset: content.startIndex, literal: content[...], tokenType: .line, children: []), Token(lineNumber: lineNumber, lineOffset: content.startIndex, literal: "", tokenType: .indent, children: [])]
        for index in content.indices {
            let char = content[index]
            let currentTokenType = hierarchy.head.tokenType
            switch satisfies(tokenType: currentTokenType, char: char) {
            case .satisfies:
                continue
            case .newToken: // close current, probably open new
                var last = hierarchy.popLast()!
                last.literal = content[last.lineOffset..<index] // notice ..<, not including current
                hierarchy.head.children.append(last)
                if !maybeHandleClosingBrackets(hierarchy: &hierarchy, content: content, char: char, index: index) {
                    let resolved = newTokenType(previous: currentTokenType, char: char)
                    hierarchy.append(Token(lineNumber: lineNumber, lineOffset: index, literal: "", tokenType: resolved, children: []))
                    if resolved == .squareBrackets || resolved == .parentheses || resolved == .curlyBraces {
                        hierarchy.append(Token(lineNumber: lineNumber, lineOffset: content.index(after: index), literal: "", tokenType: .ignoreableWhiteSpace, children: []))
                    }
                }
            case .satisfiesAndTerminates:
                popHierarchyClosing(hierarchy: &hierarchy, content: content, index: index)
                hierarchy.append(Token(lineNumber: lineNumber, lineOffset: content.index(after: index), literal: "", tokenType: .ignoreableWhiteSpace, children: []))
            case .satisfiesAndCloses:
                popHierarchyClosing(hierarchy: &hierarchy, content: content, index: index)
            case .satisfiesSubToken(let subtokenType):
                hierarchy.append(Token(lineNumber: lineNumber, lineOffset: index, literal: "", tokenType: subtokenType, children: []))
            case .changeCurrentType(let tokenType):
                hierarchy.head.tokenType = tokenType
            }
        }
        while hierarchy.count > 1 {
            var last = hierarchy.popLast()!
            last.literal = content[last.lineOffset...]
            hierarchy.head.children.append(last)
        }
        return hierarchy[0]
    }
    
    func maybeHandleClosingBrackets(hierarchy: inout [Token], content: String, char: Character, index: String.Index) -> Bool {
        switch char {
        case "]":
            if hierarchy.head.tokenType == .squareBrackets {
                popHierarchyClosing(hierarchy: &hierarchy, content: content, index: index)
            } else {
                print("Error: brackets incorrectly closed")
            }
        case ")":
            if hierarchy.head.tokenType == .parentheses {
                popHierarchyClosing(hierarchy: &hierarchy, content: content, index: index)
            } else {
                print("Error: parentheses incorrectly closed")
            }
        case "}":
            if hierarchy.head.tokenType == .curlyBraces {
                popHierarchyClosing(hierarchy: &hierarchy, content: content, index: index)
            } else {
                print("Error: braces incorrectly closed")
            }
        default:
            return false
        }
        hierarchy.append(Token(lineNumber: lineNumber, lineOffset: content.index(after: index), literal: "", tokenType: .ignoreableWhiteSpace, children: []))
        return true
    }
    
    func popHierarchyClosing(hierarchy: inout [Token], content: String, index: String.Index) {
        var last = hierarchy.popLast()!
        last.literal = content[last.lineOffset...index]
        hierarchy.head.children.append(last)
    }
    
    // when the previous character was of type `tokenType`, is the next too?
    func satisfies(tokenType: TokenType, char: Character) -> SatisfiesResult {
        switch tokenType {
        case .ignoreableWhiteSpace:
            return char.isWhitespace ? .satisfies : .newToken
        case .indent:
            return char == "\t" ? .satisfies : .newToken
        case .slashOperator:
            if char == "/" {
                return .changeCurrentType(.comment)
            }
            return .newToken
        case .comment:
            if char == "/" {
                return .changeCurrentType(.docComment)
            }
            return .satisfiesSubToken(.commentContent)
        case .docComment:
            return .satisfiesSubToken(.commentContent)
        case .commentContent:
            return .satisfies
        case .identifier, .label:
            return char.isASCII && (char.isLetter || char.isNumber || char == "_") ? .satisfies : .newToken
        case .commandName:
            return char.isASCII && char.isLetter ? .satisfies : .newToken
        case .numberLiteral:
            if char == "f" || char == "F" || char == "º" || char == "°" {
                return .satisfiesAndTerminates
            }
            if char == "," {
                return .changeCurrentType(.posLiteral)
            }
            return char.isASCII && (char.isNumber || char == ".") ? .satisfies : .newToken
        case .posLiteral:
            return char.isASCII && (char.isNumber || char == ".") ? .satisfies : .newToken
        case .stringLiteral:
            if char == "\\" {
                return .satisfiesSubToken(.stringLiteralEscapeSequence)
            } else if char == "\"" {
                return .satisfiesAndTerminates
            } else {
                return .satisfies
            }
        case .fileLiteral:
            if char == "\\" {
                return .satisfiesSubToken(.stringLiteralEscapeSequence)
            } else if char == "\'" {
                return .satisfiesAndTerminates
            } else {
                return .satisfies
            }
        case .stringLiteralEscapeSequence:
            return .satisfiesAndCloses
        case .lambdaHatOperator, .labelPrefixOperator, .comma, .dot, .operator, .assignmentOperator:
            return .newToken
        case .methodCallOperator:
            if char == ":" {
                return .changeCurrentType(.labelPrefixOperator)
            } else {
                return .newToken
            }
        case .squareBrackets, .parentheses, .curlyBraces:
            preconditionFailure("token type should never be current")
        case .line, .variable, .function, .method, .type, .keyword, .enumCase, .booleanLiteral, .nullLiteral, .assignmentCompound, .namespaceSeparator:
            preconditionFailure("token type is never yielded at this point")
        case .unresolved:
            return .newToken
        }
    }
    
    /// When a new token is encountered. Most of the time, previous is ignoreable. Only used for identifying labels.
    func newTokenType(previous: TokenType, char: Character) -> TokenType {
        if char.isWhitespace {
            return .ignoreableWhiteSpace
        }
        if char.isASCII {
            if char.isNumber {
                return .numberLiteral
            } else if char.isLetter || char == "_" || char == "$" {
                if previous == .labelPrefixOperator {
                    return .label
                } else {
                    return .identifier
                }
            }
        }
        switch char {
        case "/":
            return .slashOperator
        case ".":
            return .dot
        case "^":
            return .lambdaHatOperator
        case ":":
            return .methodCallOperator
        case ",":
            return .comma
        case "=":
            return .assignmentOperator
        case "#":
            return .commandName
        case "\"":
            return .stringLiteral
        case "\'":
            return .fileLiteral
        case "+", "-", "*", "%", "<", ">", "≥", "≤", "~", "!", "&", "|", "≠":
            return .operator
        case "[": // these are handled specially
            return .squareBrackets
        case "(":
            return .parentheses
        case "{":
            return .curlyBraces
        default:
            return .unresolved
        }
    }
    
    enum SatisfiesResult {
        /// The character is a valid part of this token type
        case satisfies
        /// The character isn't part of the current token, create a new
        case newToken
        /// The character is a part of this token, but the next character to parse will not. forces an empty whitespace token.
        case satisfiesAndTerminates
        /// The character is a part of this token, but the next character to parse will not, by closing a children context (next token will be part of the parent)
        case satisfiesAndCloses
        /// The character opens a subtoken with the given type
        case satisfiesSubToken(TokenType)
        /// The character is still a part of the same token, but the type that was given is wrong, change it.
        case changeCurrentType(TokenType)
    }
}

extension Array {
    /// Same as `last`, but with a setter
    var head: Element {
        get {
            self[count - 1]
        }
        set {
            self[count - 1] = newValue
        }
    }
}

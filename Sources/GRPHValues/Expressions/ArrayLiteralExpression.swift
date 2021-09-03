//
//  ArrayLiteralExpression.swift
//  Graphism
//
//  Created by Emil Pedersen on 03/07/2020.
//

import Foundation

public struct ArrayLiteralExpression: Expression {
    public let wrapped: GRPHType
    public let values: [Expression]
    
    public func getType(context: CompilingContext, infer: GRPHType) throws -> GRPHType {
        ArrayType(content: wrapped)
    }
    
    public var string: String {
        var str = "<\(wrapped.string)>{"
        if values.isEmpty {
            return "\(str)}"
        }
        for exp in values {
            if let pos = exp as? ConstantExpression,
               pos.value is Pos {
                str += "[\(exp.string)], " // only location where Pos expressions are bracketized
            } else {
                str += "\(exp.bracketized), "
            }
        }
        return "\(str.dropLast(2))}"
    }
    
    public var needsBrackets: Bool { false }
}

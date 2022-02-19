//
//  ConstructorExpression.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 19/02/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import GRPHValues
import LLVM

extension ConstructorExpression: RepresentableExpression {
    func build(generator: IRGenerator) throws -> IRValue {
        switch constructor.storage {
        case .generic(signature: "{T}(T wrapped...)"), .generic(signature: "funcref<T><>(T wrapped)"):
            preconditionFailure("not implemented")
        case .generic(signature: "T?(T wrapped?)"):
            let type = constructor.type as! OptionalType
            if let wrapped = values[safe: 0] {
                return try generator.builder.buildInsertValue(aggregate: type.getLLVMType().constant(values: [true, type.wrapped.findLLVMType().undef()]), element: wrapped.tryBuilding(generator: generator, expect: type.wrapped), index: 1)
            } else {
                return try type.getLLVMType().null()
            }
        case .generic(signature: "tuple(T wrapped...)"):
            let type = constructor.type as! TupleType
            return try type.content.indices.reduce(try type.asLLVM().undef()) { (curr, i) in
                return try generator.builder.buildInsertValue(aggregate: curr, element: values[i]!.tryBuilding(generator: generator, expect: type.content[i]), index: i)
            }
        case .native:
            preconditionFailure("constructors not implemented")
        case .generic(signature: let sig):
            preconditionFailure("Generic constructor with signature \(sig) not found")
        }
    }
}

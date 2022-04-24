//
//  ValueWitnessTable.swift
//  GRPH IRGen
// 
//  Created by Emil Pedersen on 23/04/2022.
//  Copyright © 2020 Snowy_1803. All rights reserved.
// 
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

/// This structure contains the name of the stdlib functions which handles ARC and co.
struct ValueWitnessTable {
    /// Returns an owned copy of a value, in `dest`
    ///
    /// For value types, it recursively copies its members (copy)
    /// For reference types, it increases the reference count (retain)
    /// The prototype of such a function is usually:
    /// ```c
    /// void grphvwt_copy_sometype(void *restrict dest, void *restrict src, struct typetable *restrict type)
    /// ```
    var copy: String
    /// Destroys a copy of a value
    ///
    /// For value types, it recursively destroys its members (copy)
    /// For reference types, it decreases the reference count (release)
    /// The prototype of such a function is usually:
    /// ```c
    /// void grphvwt_destroy_sometype(void *restrict value, struct typetable *restrict type)
    /// ```
    var destroy: String
}

extension ValueWitnessTable {
    /// This vwt just copies bytes, and destroy is a noop
    static let trivial = ValueWitnessTable(copy: "grphvwt_copy_trivial", destroy: "grphvwt_destroy_trivial")
    /// This vwt retains and releases reference types
    static let ref = ValueWitnessTable(copy: "grphvwt_retain_ref", destroy: "grphvwt_release_ref")
    /// This vwt uses its content's vwt
    static let existential = ValueWitnessTable(copy: "grphvwt_copy_mixed", destroy: "grphvwt_destroy_mixed")
    /// This vwt uses its content's vwt if it's not null
    static let optionalRecursive = ValueWitnessTable(copy: "grphvwt_copy_optional", destroy: "grphvwt_destroy_optional")
    /// This vwt uses each of its content's vwt
    static let tupleRecursive = ValueWitnessTable(copy: "grphvwt_copy_tuple", destroy: "grphvwt_destroy_tuple")
    /// This vwt retains and releases its box if it is mortal
    static let string = ValueWitnessTable(copy: "grphvwt_retain_string", destroy: "grphvwt_release_string")
    /// This vwt retains and releases its box if it is mortal
    static let font = ValueWitnessTable(copy: "grphvwt_retain_font", destroy: "grphvwt_release_font")
}

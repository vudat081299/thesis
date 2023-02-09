//
//  Storing.swift
//  VegaPunk
//
//  Created by Dat Vu on 03/02/2023.
//

import Foundation

protocol Storing {
    associatedtype T
    /// This is a file name or NSUserDefaults key
    func store()
//    func store() -> FunctionResult
    static func retrieve() -> T
//    mutating func update()
    static func remove()
}

enum FunctionResult: Int {
    case success, failure
}

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
    static var key: String { get }
    func store()
    static func retrieve() -> T
    mutating func update()
}

enum FunctionResult: Int {
    case success, failure
}

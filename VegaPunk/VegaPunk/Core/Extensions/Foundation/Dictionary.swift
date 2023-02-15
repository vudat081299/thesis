//
//  Dictionary.swift
//  VegaPunk
//
//  Created by Dat Vu on 14/02/2023.
//

import Foundation

extension Dictionary where Key == String {
    func convert<T: Decodable>(to type: T.Type) throws -> T {
        do {
            let json = try JSONSerialization.data(withJSONObject: self)
            let decoder = JSONDecoder()
            let decodedObject = try decoder.decode(type, from: json)
            return decodedObject
        } catch {
            throw error
        }
    }
}

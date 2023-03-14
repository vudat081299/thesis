//
//  Dictionary.swift
//  VegaPunk
//
//  Created by Dat Vu on 14/02/2023.
//

import Foundation

extension Dictionary where Key == String {
    /// Convert from `Dictionary` to `Object`.
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
extension User {
    /// Convert from `Object` to `Dictionary`.
    func toDictionary() throws -> Dictionary<String, String> {
        do {
            let encodedData = try JSONEncoder().encode(self)
            let json = try JSONSerialization.jsonObject(with: encodedData, options: .mutableContainers) as! [String: String]
            return json
        } catch {
            throw error
        }
    }
}
extension WebSocketPackage {
    /// Convert from `Object` to `Dictionary`.
    func toDictionary() throws -> Dictionary<String, String> {
        do {
            let encodedData = try JSONEncoder().encode(self)
            let json = try JSONSerialization.jsonObject(with: encodedData, options: .mutableContainers) as! [String: String]
            return json
        } catch {
            throw error
        }
    }
}
extension Data {
    /// Convert from `Data` to `JSON`.
    func convertToJSON() -> String? {
        return String(data: self, encoding: .utf8)
    }
}

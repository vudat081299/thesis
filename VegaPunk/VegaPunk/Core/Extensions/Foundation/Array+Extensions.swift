//
//  Array+Extensions.swift
//  VegaPunk
//
//  Created by Dat Vu on 09/01/2023.
//

import Foundation

extension Array where Element == ResolveMapping {
    func flatten() -> [Mapping] {
        self.map { $0.flatten() }
    }
}
extension Array where Element == Pivot {
    func flattenToChatBoxes() -> [UUID] {
        self.map { $0.chatBoxId }
    }
}
extension Array where Element == ResolvePivot {
    func hasChatBox(between mappingIds: [UUID]) -> UUID? {
        let flattenPivot = self.map { $0.flatten() }
        let firstSet = Set(flattenPivot.filter { $0.mappingId == mappingIds[0] }.flattenToChatBoxes())
        let secondSet = Set(flattenPivot.filter { $0.mappingId == mappingIds[1] }.flattenToChatBoxes())
        let intersection = firstSet.intersection(secondSet)
        if intersection.count > 0 {
            return intersection.first
        }
        return nil
    }
}

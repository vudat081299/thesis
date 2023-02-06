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


// MARK: - User
//extension Array where Element == User {
//    
//    subscript(mappingIds: [UUID]) -> [User] {
//        get {
//            return self.filter { $0.mappingId == mappingId }.map { $0.chatBoxId }
//        }
//    }
//}


// MARK: - MappingChatBoxPivot
extension Array where Element == MappingChatBoxPivot {
    
    /// Get all chatBoxIds where a user is a member
    /// - Returns: List of chatBoxId
    subscript(mappingId: UUID) -> [UUID] {
        get {
            return self.filter { $0.mappingId == mappingId }.map { $0.chatBoxId }
        }
    }
    
    /// Get all mappingIds where are member mappingIds in chatBox
    /// - Returns: List of mappingId
    subscript(mappingId: UUID, chatBoxId: UUID) -> [UUID] {
        get {
            return self.filter { $0.chatBoxId == chatBoxId && $0.mappingId != mappingId }.map { $0.mappingId }
        }
    }
    
    func flattenToChatBoxes() -> [UUID] {
        self.map { $0.chatBoxId }
    }
    
    func hasChatBox(between mappingIds: [UUID]) -> UUID? {
        let firstSet = Set(self.filter { $0.mappingId == mappingIds[0] }.flattenToChatBoxes())
        let secondSet = Set(self.filter { $0.mappingId == mappingIds[1] }.flattenToChatBoxes())
        let intersection = firstSet.intersection(secondSet)
        if intersection.count > 0 {
            return intersection.first
        }
        return nil
    }
}


// MARK: - ChatBox
extension Array where Element == ChatBox {
    /// Find ChatBox() with chatBoxId
    /// - Returns: ChatBox()
    subscript(chatBoxId: UUID) -> ChatBox? {
        get {
            return self.filter { $0.id == chatBoxId }.first
        }
    }
    
    /// Find List ChatBox() with list chatBoxId
    /// - Returns: [ChatBox]
    subscript(chatBoxIds: [UUID]) -> [ChatBox] {
        get {
            return self.filter { chatBoxIds.contains($0.id) }
        }
    }
}


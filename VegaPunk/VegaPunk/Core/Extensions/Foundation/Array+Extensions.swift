//
//  Array+Extensions.swift
//  VegaPunk
//
//  Created by Dat Vu on 09/01/2023.
//

import Foundation

extension Array where Element == Mapping.Resolve {
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


// MARK: - Message
extension Array where Element == Message {
    func groupByChatBox() -> Dictionary<UUID, [Message]> {
        let groupedMessagesByChatBox = Dictionary(grouping: self, by: { $0.chatBoxId })
        return groupedMessagesByChatBox
    }
    mutating func transformStructure() -> [[Message]] {
        self.sort(by: >)
        var customStructure = [[Message]]()
        var element = [Message]()
        var currentMappingId: UUID?
        let countMessages = self.count
        self.enumerated().forEach { (index, message) in
            if (currentMappingId != nil && message.sender! == currentMappingId) {
                element.append(message)
            } else {
                element = [message]
                currentMappingId = message.sender
            }
            let nextIndex = index + 1
            if nextIndex < count {
                if self[nextIndex].sender != currentMappingId {
                    customStructure.append(element)
                }
            } else {
                customStructure.append(element)
            }
        }
        return customStructure
    }
    func cacheLastest() {
        if count > 1 {
            self.max { $0.createdAt < $1.createdAt }?.store()
        } else if count == 1 {
            self[0].store()
        }
    }
}


// MARK: - Friend
extension Array where Element == User {
    func clean() -> Friend {
        return Friend(self.filter { $0.mappingId != nil })
    }
}


// MARK: - ChatBoxExtractedData
extension Array where Element == ChatBoxExtractedData {
    mutating func retrieve(with mappingId: UUID) {
        self = []
        var chatBoxes = ChatBoxes.retrieve().chatBoxes
        let pivots = MappingChatBoxPivots.retrieve().pivots
        let userChatBoxIds = pivots[mappingId]
        chatBoxes = chatBoxes.filter { userChatBoxIds.contains($0.id) }
        chatBoxes.forEach {
            let lastestMessage = Message.retrieve(with: $0.id)
            let members = pivots[mappingId, $0.id]
            self.append(ChatBoxExtractedData(chatBox: $0, lastestMessage: lastestMessage, members: members))
        }
        self.sort(by: >)
    }
}


// MARK:
extension Array where Element == UUID {
    func retrieveUsers() -> [User] {
        Friend.retrieve().friends.filter {
            if let mappingId = $0.mappingId {
                return self.contains(mappingId)
            }
            return false
        }
    }
}

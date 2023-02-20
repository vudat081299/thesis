//
//  Array+Extensions.swift
//  VegaPunk
//
//  Created by Dat Vu on 09/01/2023.
//

import Foundation


// MARK: - Mapping.Resolve
extension Array where Element == Mapping.Resolve {
    func flatten() -> [Mapping] {
        self.map { $0.flatten() }
    }
}


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


// MARK: - [Message]
extension Array where Element == [ChatBoxMessage] {
    mutating func receive(_ messages: [ChatBoxMessage]) {
        messages.forEach { message in
            if count > 0 {
                if (message.sender == self.last?.last?.sender) {
                    self[count - 1].append(message)
                } else {
                    self.append([message])
                }
            } else {
                self[0] = [message]
            }
        }
    }
}


// MARK: - Message
extension Array where Element == ChatBoxMessage {
    func groupByChatBox() -> Dictionary<UUID, [ChatBoxMessage]> {
        let groupedMessagesByChatBox = Dictionary(grouping: self, by: { $0.chatBoxId })
        return groupedMessagesByChatBox
    }
    mutating func transformStructure() -> [[ChatBoxMessage]] {
        self.sort(by: <)
        var customStructure = [[ChatBoxMessage]]()
        var element = [ChatBoxMessage]()
        var currentMappingId: UUID?
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
    mutating func receive(_ messages: [ChatBoxMessage]) {
        self += messages
    }
}


// MARK: - Friend
extension Array where Element == User {
    func clean() -> Friend {
        return Friend(self.filter { $0.mappingId != nil })
    }
}


// MARK: - UUID
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


// MARK: - View model
extension Array where Element == UserViewModel {
    mutating func retrieve() {
        self = []
        let mappings = Mappings.retrieve()
        let friends = Friend.retrieve().friends
        friends.forEach {
            if let friendId = $0.id,
               let friendMappingId = mappings.mappingId(friendId) {
                self.append(UserViewModel(mappingId: friendMappingId, user: $0))
            }
        }
        self.sort(by: {
            if let join0 = $0.user.join,
               let join1 = $1.user.join {
                return join0 > join1
            }
            return false
        })
    }
}
extension Array where Element == ChatBoxViewModel {
    mutating func retrieve(with mappingId: UUID, completion: (([ChatBoxViewModel]) -> ())? = nil) {
        var chatBoxes = ChatBoxes.retrieve().chatBoxes
        handle()
        func handle() {
            self = []
            let pivots = MappingChatBoxPivots.retrieve().pivots
            let userChatBoxIds = pivots[mappingId]
            chatBoxes = chatBoxes.filter { userChatBoxIds.contains($0.id) }
            chatBoxes.forEach {
                let lastestMessage = ChatBoxMessage.retrieve(with: $0.id)
                let members = pivots[mappingId, $0.id]
                self.append(ChatBoxViewModel(chatBox: $0, lastestMessage: lastestMessage, members: members))
            }
            self = self.filter { $0.lastestMessage != nil }
            self.sort(by: >)
        }
    }
}
/// Message view model
extension Array where Element == [ChatBoxMessage] {
    mutating func retrieve(from chatBoxId: UUID) {
        var storedMessaged = Messages.retrieve(with: chatBoxId).messages
        self = storedMessaged.transformStructure()
//        var sampleData = sampleData(mappingId: (self?.user.mappingId!)!)
//        self = sampleData.transformStructure()
    }
}

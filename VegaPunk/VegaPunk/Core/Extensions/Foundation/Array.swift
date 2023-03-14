//
//  Array.swift
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
extension Array where Element == ChatboxMember {
    
    /// Get all chatBoxIds where a user is a member
    /// - Returns: List of chatboxId
    subscript(userId: UUID) -> [UUID] {
        get {
            return self.filter { $0.userId == userId }.map { $0.chatboxId }
        }
    }
    
    /// Get all mappingIds where are member mappingIds in chatbox
    /// - Returns: List of mappingId
    subscript(userId: UUID, chatboxId: UUID) -> [UUID] {
        get {
            return self.filter { $0.chatboxId == chatboxId && $0.userId != userId }.map { $0.userId }
        }
    }
    
    func flattenToChatBoxes() -> [UUID] {
        self.map { $0.chatboxId }
    }
    
    func hasChatbox(between userIds: [UUID]) -> UUID? {
        let firstSet = Set(self.filter { $0.userId == userIds[0] }.flattenToChatBoxes())
        let secondSet = Set(self.filter { $0.userId == userIds[1] }.flattenToChatBoxes())
        let intersection = firstSet.intersection(secondSet)
        for element in intersection {
            if let authenticatedUserId = AuthenticatedUser.retrieve()?.data?.id! {
                if self[authenticatedUserId, element].count == 1 {
                    return element
                }
            }
        }
        return nil
    }
}


// MARK: - Chatbox
extension Array where Element == Chatbox {
    /// Find Chatbox() with chatboxId
    /// - Returns: Chatbox()
    subscript(chatBoxId: UUID) -> Chatbox? {
        get {
            return self.filter { $0.id == chatBoxId }.first
        }
    }
    
    /// Find List Chatbox() with list chatboxId
    /// - Returns: [Chatbox]
    subscript(chatBoxIds: [UUID]) -> [Chatbox] {
        get {
            return self.filter { chatBoxIds.contains($0.id) }
        }
    }
}


// MARK: - [Message]
extension Array where Element == [ChatboxMessage] {
    mutating func receive(_ messages: [ChatboxMessage]) {
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
extension Array where Element == ChatboxMessage {
    func groupByChatBox() -> Dictionary<UUID, [ChatboxMessage]> {
        let groupedMessagesByChatBox = Dictionary(grouping: self, by: { $0.chatboxId })
        return groupedMessagesByChatBox
    }
    mutating func transformStructure() -> [[ChatboxMessage]] {
        self.sort(by: <)
        var customStructure = [[ChatboxMessage]]()
        var element = [ChatboxMessage]()
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
    mutating func receive(_ messages: [ChatboxMessage]) {
        self += messages
    }
}


// MARK: - Friend
extension Array where Element == User {
    func clean() -> Friend {
        return Friend(self.filter { $0.username != "admin" })
    }
    func getUser(with id: UUID) -> User? {
        return self.first { $0.id == id }
    }
    func getOtherUsers() -> [User] {
        let userIds = self.map { $0.id }
        return Friend.retrieve().friends.filter {
            !userIds.contains($0.id)
        }
    }
    func sortWithJoin() -> [User] {
        self.sorted(by: >)
    }
}


// MARK: - UUID
extension Array where Element == UUID {
    func retrieveUsers() -> [User] {
        Friend.retrieve().friends.filter {
            if let userId = $0.id {
                return self.contains(userId)
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
            self.append(UserViewModel(user: $0))
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
        var chatBoxes = Chatboxes.retrieve().chatboxes
        handle()
        func handle() {
            self = []
            let pivots = ChatboxMembers.retrieve().chatboxMembers
            let userChatBoxIds = pivots[mappingId]
            chatBoxes = chatBoxes.filter { userChatBoxIds.contains($0.id) }
            chatBoxes.forEach {
                let lastestMessage = ChatboxMessage.retrieve(with: $0.id)
                let members = pivots[mappingId, $0.id]
                self.append(ChatBoxViewModel(chatBox: $0, lastestMessage: lastestMessage, members: members))
            }
            self = self.filter { $0.lastestMessage != nil }
            self.sort(by: >)
        }
    }
}
/// Message view model
extension Array where Element == [ChatboxMessage] {
    mutating func retrieve(from chatBoxId: UUID) {
        var storedMessaged = Messages.retrieve(with: chatBoxId).messages
        self = storedMessaged.transformStructure()
//        var sampleData = sampleData(mappingId: (self?.user.mappingId!)!)
//        self = sampleData.transformStructure()
    }
}


// MARK: - UInt8
extension Array where Element == UInt8 {
    public init(customHex: String) {
        self.init()
        let utf8 = Array<Element>(customHex.utf8)
        let skip0x = customHex.hasPrefix("0x") ? 2 : 0
        for idx in stride(from: utf8.startIndex.advanced(by: skip0x), to: utf8.endIndex, by: utf8.startIndex.advanced(by: 2)) {
            let byteHex = "\(UnicodeScalar(utf8[idx]))\(UnicodeScalar(utf8[idx.advanced(by: 1)]))"
            if let byte = UInt8(byteHex, radix: 16) {
                self.append(byte)
            }
        }
    }
    
    func transformToHex() -> String {
        let hexValueTable = ["0", "1", "2", "3",
                             "4", "5", "6", "7",
                             "8", "9", "a", "b",
                             "c", "d", "e", "f"]
        var hexString = ""
        for number in self {
            let decimal = Int(number)
            let firstHex = decimal / 16
            let secondHex = decimal % 16
            hexString += hexValueTable[firstHex]
            hexString += hexValueTable[secondHex]
        }
        return hexString
    }
}











// MARK: - Mini tasks
extension Array where Element == CellCategory {
    func firstIndex(of category: CellCategory) -> Int {
        return self.firstIndex(where: { $0 == category })!
    }
    subscript(category: CellCategory) -> Int {
        get {
            return self.firstIndex(of: category)
        }
    }
}

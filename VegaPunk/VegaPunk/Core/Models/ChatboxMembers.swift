//
//  ChatboxMember.swift
//  VegaPunk
//
//  Created by Dat Vu on 05/02/2023.
//

import Foundation


// MARK: - Definition
/// This is a structure of `MappingChatBoxPivot` table on `Database`
struct ChatboxMember: Codable {
    let id: UUID
    let userId: UUID
    let chatboxId: UUID
    
    struct Resolve: Codable {
        let id: UUID
        let user: ResolveUUID
        let chatbox: ResolveUUID
        
        func flatten() -> ChatboxMember {
            ChatboxMember(id: id, userId: user.id, chatboxId: chatbox.id)
        }
    }
}


struct ChatboxMembers {
    var chatboxMembers: [ChatboxMember] = []
    init(_ chatboxMembers: [ChatboxMember] = []) {
        self.chatboxMembers = chatboxMembers
    }
    init(resolvePivots: [ChatboxMember.Resolve]) {
        self.chatboxMembers = resolvePivots.map { $0.flatten() }
    }
}


// MARK: - Apply Codable
extension ChatboxMembers: Codable {
    struct PivotKey: CodingKey {
        var stringValue: String
        init(stringValue: String) {
            self.stringValue = stringValue
        }

        var intValue: Int? { return nil }
        init?(intValue: Int) { return nil }

        static let id = PivotKey(stringValue: "id")
        static let userId = PivotKey(stringValue: "userId")
        static let chatboxId = PivotKey(stringValue: "chatboxId")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: PivotKey.self)
        
        for message in chatboxMembers {
            // Any product's `name` can be used as a key name.
            let pivotId = PivotKey(stringValue: message.id.uuidString)
            var productContainer = container.nestedContainer(keyedBy: PivotKey.self, forKey: pivotId)
            
            // The rest of the keys use static names defined in `ProductKey`.
            try productContainer.encode(message.userId, forKey: .userId)
            try productContainer.encode(message.chatboxId, forKey: .chatboxId)
        }
    }
    
    public init(from decoder: Decoder) throws {
        var pivots = [ChatboxMember]()
        let container = try decoder.container(keyedBy: PivotKey.self)
        for key in container.allKeys {
            // Note how the `key` in the loop above is used immediately to access a nested container.
            let productContainer = try container.nestedContainer(keyedBy: PivotKey.self, forKey: key)
            let userId = try productContainer.decode(UUID.self, forKey: .userId)
            let chatBoxId = try productContainer.decode(UUID.self, forKey: .chatboxId)

            // The key is used again here and completes the collapse of the nesting that existed in the JSON representation.
            guard let pivotId = UUID(uuidString: key.stringValue) else { continue }
            let pivot = ChatboxMember(id: pivotId, userId: userId, chatboxId: chatBoxId)
            pivots.append(pivot)
        }
        self.init(pivots)
    }
}


// MARK: - Data handler
extension ChatboxMembers {
    func store() {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath = dir.appendingPathComponent(UserDefaults.FilePaths.mappingChatBoxPivots.rawValue)
            do {
                let encoder = JSONEncoder()
//                encoder.outputFormatting = .prettyPrinted
                try encoder.encode(self).write(to: filePath, options: .atomic)
            }
            catch {
                print("Store mappingChatBoxPivots to file failed! \(error)")
            }
        }
    }
    static func retrieve() -> ChatboxMembers {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath = dir.appendingPathComponent(UserDefaults.FilePaths.mappingChatBoxPivots.rawValue)
            do {
                let jsonData = try Data(contentsOf: filePath)
                let pivots = try JSONDecoder().decode(ChatboxMembers.self, from: jsonData)
                return pivots
            }
            catch {
                print("Retrieve mappingChatBoxPivots from file failed! \(error)")
            }
        }
        return ChatboxMembers()
    }
    static func remove() {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath = dir.appendingPathComponent(UserDefaults.FilePaths.mappingChatBoxPivots.rawValue)
            do {
                try FileManager.default.removeItem(at: filePath)
            }
            catch {
                print("Remove mappingChatBoxPivots file failed! \(error)")
            }
        }
    }
}


// MARK: - Mini tasks
extension ChatboxMembers {
    var count: Int {
        return chatboxMembers.count
    }
    subscript(index: Int) -> ChatboxMember {
        get {
            // Return an appropriate subscript value here.
            return chatboxMembers[index]
        }
        set(newValue) {
            // Perform a suitable setting action here.
            chatboxMembers[index] = newValue
        }
    }
}


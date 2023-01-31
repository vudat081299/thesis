//
//  Messages.swift
//  VegaPunk
//
//  Created by Dat Vu on 01/02/2023.
//

import Foundation

// MARK: Definition
enum MediaType: String, Codable {
    case text, file
}
struct Message: Codable {
    let id: UUID!
    let createdAt: String!
    let sender: UUID!
    let chatBoxId: UUID!
    let mediaType: MediaType!
    let content: String!
}

struct Messages {
    var messages: [Message] = []
    init(_ messages: [Message] = []) {
        self.messages = messages
    }
}


// MARK: - Apply Codable
extension Messages: Codable {
    struct MessageKey: CodingKey {
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        var intValue: Int? { return nil }
        init?(intValue: Int) { return nil }

        static let id = MessageKey(stringValue: "id")!
        static let createdAt = MessageKey(stringValue: "createdAt")!
        static let sender = MessageKey(stringValue: "sender")!
        static let chatBoxId = MessageKey(stringValue: "chatBoxId")!
        static let mediaType = MessageKey(stringValue: "mediaType")!
        static let content = MessageKey(stringValue: "content")!
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: MessageKey.self)
        
        for message in messages {
            // Any product's `name` can be used as a key name.
            let messageId = MessageKey(stringValue: message.id.uuidString)!
            var productContainer = container.nestedContainer(keyedBy: MessageKey.self, forKey: messageId)
            
            // The rest of the keys use static names defined in `ProductKey`.
            try productContainer.encode(message.createdAt, forKey: .createdAt)
            try productContainer.encode(message.sender, forKey: .sender)
            try productContainer.encode(message.chatBoxId, forKey: .chatBoxId)
            try productContainer.encode(message.mediaType, forKey: .mediaType)
            try productContainer.encode(message.content, forKey: .content)
        }
    }
    
    public init(from decoder: Decoder) throws {
        var messages = [Message]()
        let container = try decoder.container(keyedBy: MessageKey.self)
        for key in container.allKeys {
            // Note how the `key` in the loop above is used immediately to access a nested container.
            let productContainer = try container.nestedContainer(keyedBy: MessageKey.self, forKey: key)
            let createdAt = try productContainer.decodeIfPresent(String.self, forKey: .createdAt)
            let sender = try productContainer.decodeIfPresent(String.self, forKey: .sender)
            let chatBoxId = try productContainer.decodeIfPresent(String.self, forKey: .chatBoxId)
            let mediaType = try productContainer.decodeIfPresent(String.self, forKey: .mediaType)
            let content = try productContainer.decodeIfPresent(String.self, forKey: .content)

            // The key is used again here and completes the collapse of the nesting that existed in the JSON representation.
            let message = Message(id: UUID(uuidString: key.stringValue)!, createdAt: createdAt, sender: UUID(uuidString: sender!), chatBoxId: UUID(uuidString: chatBoxId!), mediaType: MediaType(rawValue: mediaType!), content: content)
            messages.append(message)
        }
        self.init(messages)
    }
}


// MARK: - Data handler
extension Messages {
    func store() {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let storageFilePath = dir.appendingPathComponent("ChatBoxes")
            print("ChatBoxes storage filepath: \(storageFilePath)")
            do {
                let encoder = JSONEncoder()
//                encoder.outputFormatting = .prettyPrinted
                try encoder.encode(self).write(to: storageFilePath)
                mappingsGlobal.update()
            }
            catch {
                print("Store chatBoxes failed! \(error)")
            }
        }
    }
    static func retrieve() -> ChatBoxes {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let storageFilePath = dir.appendingPathComponent("ChatBoxes")
            print("Retrieve data from chatBoxes storage filepath: \(storageFilePath)")
            do {
                let jsonData = try Data(contentsOf: storageFilePath)
                let chatBoxes = try JSONDecoder().decode(ChatBoxes.self, from: jsonData)
                return chatBoxes
            }
            catch {
                print("Retrieve chatBoxes failed! \(error)")
            }
        }
        return ChatBoxes()
    }
    mutating func update() {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let storageFilePath = dir.appendingPathComponent("ChatBoxes")
            print("Retrieve data from chatBoxes storage filepath: \(storageFilePath)")
            do {
                let jsonData = try Data(contentsOf: storageFilePath)
                let messages = try JSONDecoder().decode(Messages.self, from: jsonData)
                self.messages = messages.messages
            }
            catch {
                print("Retrieve chatBoxes failed! \(error)")
            }
        }
    }
}


// MARK: - Mini tasks
extension Messages {
    var count: Int {
        return messages.count
    }
    subscript(index: Int) -> Message {
        get {
            // Return an appropriate subscript value here.
            return messages[index]
        }
        set(newValue) {
            // Perform a suitable setting action here.
            messages[index] = newValue
        }
    }
}

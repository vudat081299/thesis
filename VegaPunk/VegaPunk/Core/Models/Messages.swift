//
//  Messages.swift
//  VegaPunk
//
//  Created by Dat Vu on 01/02/2023.
//

import Foundation
import CryptoSwift


// MARK: - Definition
enum MediaType: String, Codable {
    case text, file, notify
}

/**
 This is a structure of `Chatbox` table on `Database`
 - `createdAt`: this is a millisecond timestamp - 13 bits of Date()
 */
struct ChatboxMessage: Hashable {
    let id: UUID
    let createdAt: String
    let sender: UUID?
    let chatboxId: UUID
    let mediaType: MediaType
    let content: String?
    
    struct Resolve: Codable {
        let id: UUID
        let createdAt: String
        let sender: UUID?
        let chatbox: ResolveUUID
        let mediaType: MediaType
        let content: String?
        
        func flatten(_ aes: AES) -> ChatboxMessage {
            do {
                let decrypted = try aes.decrypt(content!.transformToArrayUInt8())
                if let plainText = String(bytes: decrypted, encoding: .utf8) {
                    return ChatboxMessage(id: id, createdAt: createdAt, sender: sender, chatboxId: chatbox.id, mediaType: mediaType, content: plainText)
                } else {
                    return ChatboxMessage(id: id, createdAt: createdAt, sender: sender, chatboxId: chatbox.id, mediaType: mediaType, content: "Fail to load!")
                }
            } catch {
                return ChatboxMessage(id: id, createdAt: createdAt, sender: sender, chatboxId: chatbox.id, mediaType: mediaType, content: "Fail to load!")
            }
        }
    }
    
    static func == (lhs: ChatboxMessage, rhs: ChatboxMessage) -> Bool {
        return lhs.id == rhs.id
    }
    static func < (lhs: ChatboxMessage, rhs: ChatboxMessage) -> Bool {
        if lhs.createdAt == rhs.createdAt {
            return lhs.id.uuidString < rhs.id.uuidString
        }
        return lhs.createdAt < rhs.createdAt
    }
    static func > (lhs: ChatboxMessage, rhs: ChatboxMessage) -> Bool {
        if lhs.createdAt == rhs.createdAt {
            return lhs.id.uuidString > rhs.id.uuidString
        }
        return lhs.createdAt > rhs.createdAt
    }
}


// MARK: - Apply Codable
extension ChatboxMessage: Codable {
    enum Key: String, CodingKey {
        case id
        case createdAt
        case sender
        case chatBoxId
        case mediaType
        case content
    }
    
    
    // MARK: - Conform to Codable
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        sender = try container.decode(UUID?.self, forKey: .sender)
        chatboxId = try container.decode(UUID.self, forKey: .chatBoxId)
        mediaType = try container.decode(MediaType.self, forKey: .mediaType)
        content = try container.decode(String?.self, forKey: .content)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(sender, forKey: .sender)
        try container.encode(chatboxId, forKey: .chatBoxId)
        try container.encode(mediaType, forKey: .mediaType)
        try container.encode(content, forKey: .content)
    }

    // MARK: - Data handler
    func store(_ domain: UserDefaults.Keys = .lastestMessage) {
        do {
            let userData = try PropertyListEncoder().encode(self)
            UserDefaults.standard.set(userData, forKey: domain.genKey(self.chatboxId.uuidString))
        } catch {
            print("Error when saving AuthenticatedUser object!")
        }
    }
    static func retrieve(_ domain: UserDefaults.Keys = .lastestMessage, with chatBoxId: UUID) -> ChatboxMessage? {
        if let data = UserDefaults.standard.data(forKey: domain.genKey(chatBoxId.uuidString)) {
            do {
                let message = try PropertyListDecoder().decode(ChatboxMessage?.self, from: data)
                return message
            } catch {
                print("Retrieve AuthenticatedUser object failed!")
            }
        }
        return nil
    }
    static func remove(_ domain: UserDefaults.Keys = .lastestMessage, with chatBoxId: UUID) {
        UserDefaults.standard.removeObject(forKey: domain.genKey(chatBoxId.uuidString))
    }
}

struct Messages {
    var messages: [ChatboxMessage] = []
    
    init(_ messages: [ChatboxMessage] = []) {
        self.messages = messages
    }
    
    init(_ resolveMessages: [ChatboxMessage.Resolve]) {
        do {
            let aes = try AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7)
            self.messages = resolveMessages.map { $0.flatten(aes) }
        } catch {
            
        }
    }
}


// MARK: - Apply Codable
extension Messages: Codable {
    struct MessageKey: CodingKey {
        var stringValue: String
        init(stringValue: String) {
            self.stringValue = stringValue
        }

        var intValue: Int? { return nil }
        init?(intValue: Int) { return nil }

        static let id = MessageKey(stringValue: "id")
        static let createdAt = MessageKey(stringValue: "createdAt")
        static let sender = MessageKey(stringValue: "sender")
        static let chatBoxId = MessageKey(stringValue: "chatboxId")
        static let mediaType = MessageKey(stringValue: "mediaType")
        static let content = MessageKey(stringValue: "content")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: MessageKey.self)
        
        for message in messages {
            // Any product's `name` can be used as a key name.
            let messageId = MessageKey(stringValue: message.id.uuidString)
            var productContainer = container.nestedContainer(keyedBy: MessageKey.self, forKey: messageId)
            
            // The rest of the keys use static names defined in `ProductKey`.
            try productContainer.encode(message.createdAt, forKey: .createdAt)
            try productContainer.encode(message.sender, forKey: .sender)
            try productContainer.encode(message.chatboxId, forKey: .chatBoxId)
            try productContainer.encode(message.mediaType, forKey: .mediaType)
            try productContainer.encode(message.content, forKey: .content)
        }
    }
    
    public init(from decoder: Decoder) throws {
        var messages = [ChatboxMessage]()
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
            guard let createdAt = createdAt,
                  let sender = sender,
                  let chatBoxId = chatBoxId,
                  let mediaType = mediaType,
                  let content = content,
                  let messageUUID = UUID(uuidString: key.stringValue),
                  let senderUUID = UUID(uuidString: sender),
                  let chatBoxId = UUID(uuidString: chatBoxId)
            else { continue }
            let message = ChatboxMessage(id: messageUUID, createdAt: createdAt, sender: senderUUID, chatboxId: chatBoxId, mediaType: MediaType(rawValue: mediaType)!, content: content)
            messages.append(message)
        }
        self.init(messages)
    }
}


// MARK: - Data handler
extension Messages {
    /// Fetch from server.
    /// - Note: Fetch messages from user's chatBoxes and store them.
    static func fetch() {
        if let userId = AuthenticatedUser.retrieve()?.data?.id {
            ChatboxMembers.retrieve().chatboxMembers[userId].forEach {
                RequestEngine.getMessagesOfChatBox($0, onSuccess: { messages in
                    Messages(messages).store()
                })
            }
        }
    }
    static func fetch(_ chatBoxId: UUID, _ completion: (() -> ())? = nil) {
        RequestEngine.getMessagesOfChatBox(chatBoxId, onSuccess: { messages in
            Messages(messages).store()
        }) {
            if let completion = completion { completion() }
        }
    }
    func store() {
        let groupedMessagesByChatBox = messages.groupByChatBox()
        for (chatBoxId, messages) in groupedMessagesByChatBox {
            let storedMessages = Messages.retrieve(with: chatBoxId).messages
            let allMessages = storedMessages + messages
            let messages = Messages(Array(Set(allMessages)).sorted(by: <))
            messages.messages.cacheLastest()
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let storageDirectoryPath = dir.appendingPathComponent(UserDefaults.FilePaths.messages.rawValue)
                let filePath = storageDirectoryPath.appendingPathComponent(chatBoxId.uuidString)
                do {
                    FileManager.default.confirmFileExists(atPath: storageDirectoryPath, isDirectory: true)
                    let encoder = JSONEncoder()
    //                encoder.outputFormatting = .prettyPrinted
                    try encoder.encode(messages).write(to: filePath, options: .atomic)
                }
                catch {
                    print("Store messages to file failed! \(error)")
                }
            }
        }
    }
    static func retrieve(with chatBoxId: UUID) -> Messages {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath = dir.appendingPathComponent(UserDefaults.FilePaths.messages.rawValue).appendingPathComponent(chatBoxId.uuidString)
            do {
                let jsonData = try Data(contentsOf: filePath)
                let messages = try JSONDecoder().decode(Messages.self, from: jsonData)
                return Messages(messages.messages.sorted(by: <))
            }
            catch {
                print("Retrieve messages from file failed! \(error)")
            }
        }
        return Messages()
    }
    static func remove() {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath = dir.appendingPathComponent(UserDefaults.FilePaths.messages.rawValue)
            do {
                try FileManager.default.removeItem(at: filePath)
            }
            catch {
                print("Remove messages file failed! \(error)")
            }
        }
    }
}


// MARK: - Mini tasks
extension Messages {
    var count: Int {
        return messages.count
    }
    subscript(index: Int) -> ChatboxMessage {
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

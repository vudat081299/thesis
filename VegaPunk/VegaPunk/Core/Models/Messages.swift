//
//  Messages.swift
//  VegaPunk
//
//  Created by Dat Vu on 01/02/2023.
//

import Foundation


// MARK: - Definition
enum MediaType: String, Codable {
    case text, file, notify
}

/**
 This is a structure of `ChatBox` table on `Database`
 - `createdAt`: this is a millisecond timestamp - 13 bits of Date()
 */
struct ChatBoxMessage: Hashable {
    let id: UUID
    let createdAt: String
    let sender: UUID?
    let chatBoxId: UUID
    let mediaType: MediaType
    let content: String?
    
    struct Resolve: Codable {
        let id: UUID
        let createdAt: String
        let sender: UUID?
        let chatBox: ResolveUUID
        let mediaType: MediaType
        let content: String?
        
        func flatten() -> ChatBoxMessage {
            ChatBoxMessage(id: id, createdAt: createdAt, sender: sender, chatBoxId: chatBox.id, mediaType: mediaType, content: content)
        }
    }
    
    static func == (lhs: ChatBoxMessage, rhs: ChatBoxMessage) -> Bool {
        return lhs.id == rhs.id
    }
    static func < (lhs: ChatBoxMessage, rhs: ChatBoxMessage) -> Bool {
        if lhs.createdAt == rhs.createdAt {
            return lhs.id.uuidString < rhs.id.uuidString
        }
        return lhs.createdAt < rhs.createdAt
    }
    static func > (lhs: ChatBoxMessage, rhs: ChatBoxMessage) -> Bool {
        if lhs.createdAt == rhs.createdAt {
            return lhs.id.uuidString > rhs.id.uuidString
        }
        return lhs.createdAt > rhs.createdAt
    }
}


// MARK: - Apply Codable
extension ChatBoxMessage: Codable {
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
        chatBoxId = try container.decode(UUID.self, forKey: .chatBoxId)
        mediaType = try container.decode(MediaType.self, forKey: .mediaType)
        content = try container.decode(String?.self, forKey: .content)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(sender, forKey: .sender)
        try container.encode(chatBoxId, forKey: .chatBoxId)
        try container.encode(mediaType, forKey: .mediaType)
        try container.encode(content, forKey: .content)
    }

    // MARK: - Data handler
    func store(_ domain: UserDefaults.Keys = .lastestMessage) {
        do {
            let userData = try PropertyListEncoder().encode(self)
            UserDefaults.standard.set(userData, forKey: domain.genKey(self.chatBoxId.uuidString))
        } catch {
            print("Error when saving AuthenticatedUser object!")
        }
    }
    static func retrieve(_ domain: UserDefaults.Keys = .lastestMessage, with chatBoxId: UUID) -> ChatBoxMessage? {
        if let data = UserDefaults.standard.data(forKey: domain.genKey(chatBoxId.uuidString)) {
            do {
                let message = try PropertyListDecoder().decode(ChatBoxMessage?.self, from: data)
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
    var messages: [ChatBoxMessage] = []
    
    init(_ messages: [ChatBoxMessage] = []) {
        self.messages = messages
    }
    
    init(_ resolveMessages: [ChatBoxMessage.Resolve]) {
        self.messages = resolveMessages.map { $0.flatten() }
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
        static let chatBoxId = MessageKey(stringValue: "chatBoxId")
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
            try productContainer.encode(message.chatBoxId, forKey: .chatBoxId)
            try productContainer.encode(message.mediaType, forKey: .mediaType)
            try productContainer.encode(message.content, forKey: .content)
        }
    }
    
    public init(from decoder: Decoder) throws {
        var messages = [ChatBoxMessage]()
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
            let message = ChatBoxMessage(id: messageUUID, createdAt: createdAt, sender: senderUUID, chatBoxId: chatBoxId, mediaType: MediaType(rawValue: mediaType)!, content: content)
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
        if let mappingId = AuthenticatedUser.retrieve()?.data?.mappingId {
            MappingChatBoxPivots.retrieve().pivots[mappingId].forEach {
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
    subscript(index: Int) -> ChatBoxMessage {
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

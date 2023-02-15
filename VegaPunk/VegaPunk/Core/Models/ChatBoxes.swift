//
//  ChatBoxes.swift
//  VegaPunk
//
//  Created by Dat Vu on 09/01/2023.
//

import Foundation

var chatBoxesGlobal = ChatBoxes.retrieve()


// MARK: - Definition
/// This is a structure of `ChatBox` table on `Database`
struct ChatBox: Codable {
    let id: UUID
    let name: String?
    let avatar: String?
}
extension ChatBox: Hashable {} // To use UICollectionViewDiffableDataSource

struct ChatBoxes {
    var chatBoxes: [ChatBox] = []
    init(_ chatBoxes: [ChatBox] = []) {
        self.chatBoxes = chatBoxes
    }
}


// MARK: - Apply Codable
extension ChatBoxes: Codable {
    struct ChatBoxKey: CodingKey {
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        var intValue: Int? { return nil }
        init?(intValue: Int) { return nil }

        static let id = ChatBoxKey(stringValue: "id")!
        static let name = ChatBoxKey(stringValue: "name")!
        static let avatar = ChatBoxKey(stringValue: "avatar")!
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ChatBoxKey.self)
        
        for chatBox in chatBoxes {
            // Any product's `name` can be used as a key name.
            let chatBoxId = ChatBoxKey(stringValue: chatBox.id.uuidString)!
            var productContainer = container.nestedContainer(keyedBy: ChatBoxKey.self, forKey: chatBoxId)
            
            // The rest of the keys use static names defined in `ProductKey`.
            try productContainer.encode(chatBox.name, forKey: .name)
            try productContainer.encode(chatBox.avatar, forKey: .avatar)
        }
    }
    
    public init(from decoder: Decoder) throws {
        var chatBoxes = [ChatBox]()
        let container = try decoder.container(keyedBy: ChatBoxKey.self)
        for key in container.allKeys {
            // Note how the `key` in the loop above is used immediately to access a nested container.
            let productContainer = try container.nestedContainer(keyedBy: ChatBoxKey.self, forKey: key)
            let name = try productContainer.decodeIfPresent(String.self, forKey: .name)
            let avatar = try productContainer.decodeIfPresent(String.self, forKey: .avatar)

            // The key is used again here and completes the collapse of the nesting that existed in the JSON representation.
            let chatBox = ChatBox(id: UUID(uuidString: key.stringValue)!, name: name, avatar: avatar)
            chatBoxes.append(chatBox)
        }
        self.init(chatBoxes)
    }
}


// MARK: - Data handler
extension ChatBoxes: Storing {
    func store() {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath = dir.appendingPathComponent(UserDefaults.FilePaths.chatBoxes.rawValue)
            do {
                let encoder = JSONEncoder()
//                encoder.outputFormatting = .prettyPrinted
                try encoder.encode(self).write(to: filePath, options: .atomic)
            }
            catch {
                print("Store chatBoxes to file failed! \(error)")
            }
        }
    }
    static func retrieve() -> ChatBoxes {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath = dir.appendingPathComponent(UserDefaults.FilePaths.chatBoxes.rawValue)
            do {
                let jsonData = try Data(contentsOf: filePath)
                let chatBoxes = try JSONDecoder().decode(ChatBoxes.self, from: jsonData)
                return chatBoxes
            }
            catch {
                print("Retrieve chatBoxes from file failed! \(error)")
            }
        }
        return ChatBoxes()
    }
    static func remove() {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let storageFilePath = dir.appendingPathComponent(UserDefaults.FilePaths.chatBoxes.rawValue)
            do {
                try FileManager.default.removeItem(at: storageFilePath)
            }
            catch {
                print("Remove chatBoxes file failed! \(error)")
            }
        }
    }
}


// MARK: - Mini tasks
extension ChatBoxes {
    var count: Int {
        return chatBoxes.count
    }
}

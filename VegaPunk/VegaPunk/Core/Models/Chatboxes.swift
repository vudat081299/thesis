//
//  Chatboxes.swift
//  VegaPunk
//
//  Created by Dat Vu on 09/01/2023.
//

import Foundation

var chatBoxesGlobal = Chatboxes.retrieve()


// MARK: - Definition
/// This is a structure of `Chatbox` table on `Database`
struct Chatbox: Codable {
    let id: UUID
    let name: String?
    let avatar: String?
}
extension Chatbox: Hashable {} // To use UICollectionViewDiffableDataSource

struct Chatboxes {
    var chatboxes: [Chatbox] = []
    init(_ chatboxes: [Chatbox] = []) {
        self.chatboxes = chatboxes
    }
}


// MARK: - Apply Codable
extension Chatboxes: Codable {
    struct ChatboxKey: CodingKey {
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        var intValue: Int? { return nil }
        init?(intValue: Int) { return nil }

        static let id = ChatboxKey(stringValue: "id")!
        static let name = ChatboxKey(stringValue: "name")!
        static let avatar = ChatboxKey(stringValue: "avatar")!
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ChatboxKey.self)
        
        for chatBox in chatboxes {
            // Any product's `name` can be used as a key name.
            let chatBoxId = ChatboxKey(stringValue: chatBox.id.uuidString)!
            var productContainer = container.nestedContainer(keyedBy: ChatboxKey.self, forKey: chatBoxId)
            
            // The rest of the keys use static names defined in `ProductKey`.
            try productContainer.encode(chatBox.name, forKey: .name)
            try productContainer.encode(chatBox.avatar, forKey: .avatar)
        }
    }
    
    public init(from decoder: Decoder) throws {
        var chatBoxes = [Chatbox]()
        let container = try decoder.container(keyedBy: ChatboxKey.self)
        for key in container.allKeys {
            // Note how the `key` in the loop above is used immediately to access a nested container.
            let productContainer = try container.nestedContainer(keyedBy: ChatboxKey.self, forKey: key)
            let name = try productContainer.decodeIfPresent(String.self, forKey: .name)
            let avatar = try productContainer.decodeIfPresent(String.self, forKey: .avatar)

            // The key is used again here and completes the collapse of the nesting that existed in the JSON representation.
            let chatBox = Chatbox(id: UUID(uuidString: key.stringValue)!, name: name, avatar: avatar)
            chatBoxes.append(chatBox)
        }
        self.init(chatBoxes)
    }
}


// MARK: - Data handler
extension Chatboxes: Storing {
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
    static func retrieve() -> Chatboxes {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath = dir.appendingPathComponent(UserDefaults.FilePaths.chatBoxes.rawValue)
            do {
                let jsonData = try Data(contentsOf: filePath)
                let chatBoxes = try JSONDecoder().decode(Chatboxes.self, from: jsonData)
                return chatBoxes
            }
            catch {
                print("Retrieve chatBoxes from file failed! \(error)")
            }
        }
        return Chatboxes()
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
extension Chatboxes {
    var count: Int {
        return chatboxes.count
    }
}

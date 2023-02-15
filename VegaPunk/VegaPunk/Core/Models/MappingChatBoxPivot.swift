//
//  MappingChatBoxPivot.swift
//  VegaPunk
//
//  Created by Dat Vu on 05/02/2023.
//

import Foundation


// MARK: - Definition
/// This is a structure of `MappingChatBoxPivot` table on `Database`
struct MappingChatBoxPivot: Codable {
    let id: UUID
    let mappingId: UUID
    let chatBoxId: UUID
    
    struct Resolve: Codable {
        let id: UUID
        let mapping: ResolveUUID
        let chatBox: ResolveUUID
        
        func flatten() -> MappingChatBoxPivot {
            MappingChatBoxPivot(id: id, mappingId: mapping.id, chatBoxId: chatBox.id)
        }
    }
}


struct MappingChatBoxPivots {
    var pivots: [MappingChatBoxPivot] = []
    init(_ pivots: [MappingChatBoxPivot] = []) {
        self.pivots = pivots
    }
    init(resolvePivots: [MappingChatBoxPivot.Resolve]) {
        self.pivots = resolvePivots.map { $0.flatten() }
    }
}


// MARK: - Apply Codable
extension MappingChatBoxPivots: Codable {
    struct PivotKey: CodingKey {
        var stringValue: String
        init(stringValue: String) {
            self.stringValue = stringValue
        }

        var intValue: Int? { return nil }
        init?(intValue: Int) { return nil }

        static let id = PivotKey(stringValue: "id")
        static let mappingId = PivotKey(stringValue: "mappingId")
        static let chatBoxId = PivotKey(stringValue: "chatBoxId")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: PivotKey.self)
        
        for message in pivots {
            // Any product's `name` can be used as a key name.
            let pivotId = PivotKey(stringValue: message.id.uuidString)
            var productContainer = container.nestedContainer(keyedBy: PivotKey.self, forKey: pivotId)
            
            // The rest of the keys use static names defined in `ProductKey`.
            try productContainer.encode(message.mappingId, forKey: .mappingId)
            try productContainer.encode(message.chatBoxId, forKey: .chatBoxId)
        }
    }
    
    public init(from decoder: Decoder) throws {
        var pivots = [MappingChatBoxPivot]()
        let container = try decoder.container(keyedBy: PivotKey.self)
        for key in container.allKeys {
            // Note how the `key` in the loop above is used immediately to access a nested container.
            let productContainer = try container.nestedContainer(keyedBy: PivotKey.self, forKey: key)
            let mappingId = try productContainer.decode(UUID.self, forKey: .mappingId)
            let chatBoxId = try productContainer.decode(UUID.self, forKey: .chatBoxId)

            // The key is used again here and completes the collapse of the nesting that existed in the JSON representation.
            guard let pivotId = UUID(uuidString: key.stringValue) else { continue }
            let pivot = MappingChatBoxPivot(id: pivotId, mappingId: mappingId, chatBoxId: chatBoxId)
            pivots.append(pivot)
        }
        self.init(pivots)
    }
}


// MARK: - Data handler
extension MappingChatBoxPivots {
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
    static func retrieve() -> MappingChatBoxPivots {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath = dir.appendingPathComponent(UserDefaults.FilePaths.mappingChatBoxPivots.rawValue)
            do {
                let jsonData = try Data(contentsOf: filePath)
                let pivots = try JSONDecoder().decode(MappingChatBoxPivots.self, from: jsonData)
                return pivots
            }
            catch {
                print("Retrieve mappingChatBoxPivots from file failed! \(error)")
            }
        }
        return MappingChatBoxPivots()
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
extension MappingChatBoxPivots {
    var count: Int {
        return pivots.count
    }
    subscript(index: Int) -> MappingChatBoxPivot {
        get {
            // Return an appropriate subscript value here.
            return pivots[index]
        }
        set(newValue) {
            // Perform a suitable setting action here.
            pivots[index] = newValue
        }
    }
}


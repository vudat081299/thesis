//
//  Mappings.swift
//  VegaPunk
//
//  Created by Dat Vu on 08/01/2023.
//

import Foundation

var mappingsGlobal = Mappings.retrieve()

// MARK: Definition
/// This is a structure of `Mapping` table on `Database`
struct Mapping: Codable {
    let id: UUID?
    var user: ResolveUUID?
    var userId: UUID?
    
    func flatten() -> Mapping? {
        guard let user = user else { return nil }
        return Mapping(id: id, userId: user.id)
    }
}

struct Mappings {
    var mappings: [Mapping] = []
    
    init(_ mappings: [Mapping] = []) {
        self.mappings = mappings
    }
    
    init(resolveMappings: [ResolveMapping]) {
        self.mappings = resolveMappings.map { Mapping(id: $0.id, userId: $0.user.id) }
    }
}

// MARK: - Apply Codable
extension Mappings: Codable {
    struct MappingKey: CodingKey {
        var stringValue: String
        init(stringValue: String) {
            self.stringValue = stringValue
        }

        var intValue: Int? { return nil }
        init?(intValue: Int) { return nil }

        static let id = MappingKey(stringValue: "id")
        static let userId = MappingKey(stringValue: "name")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: MappingKey.self)
        
        for mapping in mappings {
            // Any product's `name` can be used as a key name.
            guard let mappingId = mapping.id else { continue }
            let mappingKeyId = MappingKey(stringValue: mappingId.uuidString)
            var productContainer = container.nestedContainer(keyedBy: MappingKey.self, forKey: mappingKeyId)
            
            // The rest of the keys use static names defined in `ProductKey`.
            try productContainer.encode(mapping.userId, forKey: .userId)
        }
    }
    
    public init(from decoder: Decoder) throws {
        var mappings = [Mapping]()
        let container = try decoder.container(keyedBy: MappingKey.self)
        for key in container.allKeys {
            // Note how the `key` in the loop above is used immediately to access a nested container.
            let productContainer = try container.nestedContainer(keyedBy: MappingKey.self, forKey: key)
            let userId = try productContainer.decode(UUID.self, forKey: .userId)

            // The key is used again here and completes the collapse of the nesting that existed in the JSON representation.
            guard let mappingUUID = UUID(uuidString: key.stringValue) else { continue }
            let mapping = Mapping(id: mappingUUID, userId: userId)
            mappings.append(mapping)
        }
        self.init(mappings)
    }
}



// MARK: - Data handler
extension Mappings: Storing {
    static var key: String {
        get {
            return "Mappings"
        }
    }
    func store() {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let storageFilePath = dir.appendingPathComponent(Mappings.key)
            print("Mappings storage filepath: \(storageFilePath)")
            do {
                let encoder = JSONEncoder()
//                encoder.outputFormatting = .prettyPrinted
                try encoder.encode(self).write(to: storageFilePath)
            }
            catch {
                print("Store mappings failed! \(error)")
            }
        }
    }
    static func retrieve() -> Mappings {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let storageFilePath = dir.appendingPathComponent(key)
            print("Retrieve data from mappings storage filepath: \(storageFilePath)")
            do {
                let jsonData = try Data(contentsOf: storageFilePath)
                let mappings = try JSONDecoder().decode(Mappings.self, from: jsonData)
                return mappings
            }
            catch {
                print("Retrieve mappings failed! \(error)")
            }
        }
        return Mappings()
    }
    mutating func update() {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let storageFilePath = dir.appendingPathComponent(Mappings.key)
            print("Retrieve data from mappings storage filepath: \(storageFilePath)")
            do {
                let jsonData = try Data(contentsOf: storageFilePath)
                let mappings = try JSONDecoder().decode(Mappings.self, from: jsonData)
                self.mappings = mappings.mappings
            }
            catch {
                print("Retrieve mappings failed! \(error)")
            }
        }
    }
}



// MARK: - Mini tasks
extension Mappings {
    var count: Int {
        return mappings.count
    }
    subscript(index: Int) -> Mapping {
        get {
            // Return an appropriate subscript value here.
            return mappings[index]
        }
        set(newValue) {
            // Perform a suitable setting action here.
            mappings[index] = newValue
        }
    }
    func mappingId(_ userId: UUID) -> UUID? {
        return mappings.filter { $0.userId == userId }.first?.id
    }
}

//
//  User+Friends.swift
//  VegaPunk
//
//  Created by Dat Vu on 08/01/2023.
//

import Foundation


// MARK: - Definition
/// This is a structure of `User` table on `Database`
struct User: Codable {
    var id: UUID?
    var token: Token?
    var name: String?
    var username: String?
    var email: String?
    var join: String?
    var bio: String?
    var phone: String?
    var birth: String?
    var siwaIdentifier: String?
    var avatar: String?
    var password: String?
    var country: String?
    var gender: Gender?
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
    static func > (lhs: User, rhs: User) -> Bool {
        return lhs.join == rhs.join
    }
}

enum Gender: Int, CaseIterable, Codable {
    case male, female, other
    static var listRawValue: [String] {
        var list = [String]()
        for item in self.allCases {
            list.append("\(item.rawValue)")
        }
        return list
    }
    var description: String {
        switch self {
        case .male:
            return "Nam"
        case .female:
            return "Nữ"
        case .other:
            return "Khác"
        }
    }
}

struct Friend {
    var friends: [User]
    init(_ friends: [User] = []) {
        self.friends = friends.filter { $0.id != AuthenticatedUser.retrieve()?.data?.id }
    }
}


// MARK: - Apply Codable
extension Friend: Codable {
    struct UserKey: CodingKey {
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        var intValue: Int? { return nil }
        init?(intValue: Int) { return nil }

        static let id = UserKey(stringValue: "id")!
        static let mappingId = UserKey(stringValue: "mappingId")!
        static let token = UserKey(stringValue: "token")!
        static let name = UserKey(stringValue: "name")!
        static let username = UserKey(stringValue: "username")!
        static let email = UserKey(stringValue: "email")!
        static let join = UserKey(stringValue: "join")!
        static let bio = UserKey(stringValue: "bio")!
        static let phone = UserKey(stringValue: "phone")!
        static let birth = UserKey(stringValue: "birth")!
        static let siwaIdentifier = UserKey(stringValue: "siwaIdentifier")!
        static let avatar = UserKey(stringValue: "avatar")!
        static let password = UserKey(stringValue: "password")!
        static let country = UserKey(stringValue: "country")!
        static let gender = UserKey(stringValue: "gender")!
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: UserKey.self)
        
        for friend in friends {
            // Any product's `name` can be used as a key name.
            let userId = UserKey(stringValue: friend.id!.uuidString)!
            var productContainer = container.nestedContainer(keyedBy: UserKey.self, forKey: userId)
            
            // The rest of the keys use static names defined in `ProductKey`.
            try productContainer.encode(friend.token, forKey: .token)
            try productContainer.encode(friend.name, forKey: .name)
            try productContainer.encode(friend.username, forKey: .username)
            try productContainer.encode(friend.email, forKey: .email)
            try productContainer.encode(friend.join, forKey: .join)
            try productContainer.encode(friend.bio, forKey: .bio)
            try productContainer.encode(friend.phone, forKey: .phone)
            try productContainer.encode(friend.birth, forKey: .birth)
            try productContainer.encode(friend.siwaIdentifier, forKey: .siwaIdentifier)
            try productContainer.encode(friend.avatar, forKey: .avatar)
            try productContainer.encode(friend.password, forKey: .password)
            try productContainer.encode(friend.country, forKey: .country)
            try productContainer.encode(friend.gender, forKey: .gender)
        }
    }
    
    public init(from decoder: Decoder) throws {
        var friends = [User]()
        let container = try decoder.container(keyedBy: UserKey.self)
        for key in container.allKeys {
            // Note how the `key` in the loop above is used immediately to access a nested container.
            let productContainer = try container.nestedContainer(keyedBy: UserKey.self, forKey: key)
            let token = try productContainer.decodeIfPresent(Token.self, forKey: .token)
            let name = try productContainer.decodeIfPresent(String.self, forKey: .name)
            let username = try productContainer.decodeIfPresent(String.self, forKey: .username)
            let email = try productContainer.decodeIfPresent(String.self, forKey: .email)
            let join = try productContainer.decodeIfPresent(String.self, forKey: .join)
            let bio = try productContainer.decodeIfPresent(String.self, forKey: .bio)
            let phone = try productContainer.decodeIfPresent(String.self, forKey: .phone)
            let birth = try productContainer.decodeIfPresent(String.self, forKey: .birth)
            let siwaIdentifier = try productContainer.decodeIfPresent(String.self, forKey: .siwaIdentifier)
            let avatar = try productContainer.decodeIfPresent(String.self, forKey: .avatar)
            let password = try productContainer.decodeIfPresent(String.self, forKey: .password)
            let country = try productContainer.decodeIfPresent(String.self, forKey: .country)
            let gender = try productContainer.decodeIfPresent(Gender.self, forKey: .gender)

            // The key is used again here and completes the collapse of the nesting that existed in the JSON representation.
            let friend = User(id: UUID(uuidString: key.stringValue)!, token: token, name: name!, username: username!, email: email, join: join, bio: bio, phone: phone, birth: birth, siwaIdentifier: siwaIdentifier, avatar: avatar, password: password, country: country, gender: gender)
            friends.append(friend)
        }
        self.init(friends)
    }
}


// MARK: - Data handler
extension Friend {
    func store() {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath = dir.appendingPathComponent(UserDefaults.FilePaths.friends.rawValue)
            do {
                let encoder = JSONEncoder()
//                encoder.outputFormatting = .prettyPrinted
                try encoder.encode(self.friends.clean()).write(to: filePath, options: .atomic)
            }
            catch {
                print("Store friends to file failed! \(error)")
            }
        }
    }
    static func retrieve() -> Friend {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath = dir.appendingPathComponent(UserDefaults.FilePaths.friends.rawValue)
            do {
                let jsonData = try Data(contentsOf: filePath)
                let friend = try JSONDecoder().decode(Friend.self, from: jsonData)
                return friend
            }
            catch {
                print("Retrieve friends from file failed! \(error)")
            }
        }
        return Friend()
    }
    static func remove() {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath = dir.appendingPathComponent(UserDefaults.FilePaths.friends.rawValue)
            do {
                try FileManager.default.removeItem(at: filePath)
            }
            catch {
                print("Remove friends file failed! \(error)")
            }
        }
    }
}


// MARK: - Mini tasks
extension Friend {
    var count: Int {
        return friends.count
    }
    subscript(index: Int) -> User {
        get {
            // Return an appropriate subscript value here.
            return friends[index]
        }
        set(newValue) {
            // Perform a suitable setting action here.
            friends[index] = newValue
        }
    }
}

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
    var mappingId: UUID?
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
    var gender: Int?
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
            let gender = try productContainer.decodeIfPresent(Int.self, forKey: .gender)

            // The key is used again here and completes the collapse of the nesting that existed in the JSON representation.
            let friend = User(id: UUID(uuidString: key.stringValue)!, name: name!, username: username!, email: email, join: join, bio: bio, phone: phone, birth: birth, siwaIdentifier: siwaIdentifier, avatar: avatar, password: password, country: country, gender: gender)
            friends.append(friend)
        }
        self.init(friends)
    }
}


// MARK: - Data handler
extension Friend: Storing {
    static var key: String {
        get {
            return "Friends"
        }
    }
    func store() {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let friendsStorageFilePath = dir.appendingPathComponent(Friend.key)
            print("Friends storage filepath: \(friendsStorageFilePath)")
            do {
                let encoder = JSONEncoder()
//                encoder.outputFormatting = .prettyPrinted
                try encoder.encode(self).write(to: friendsStorageFilePath)
            }
            catch {
                print("Store friends failed! \(error)")
            }
        }
    }
    static func retrieve() -> Friend {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let storageFilePath = dir.appendingPathComponent(key)
            print("Retrieve data from friends storage filepath: \(storageFilePath)")
            do {
                let jsonData = try Data(contentsOf: storageFilePath)
                let friend = try JSONDecoder().decode(Friend.self, from: jsonData)
                return friend
            }
            catch {
                print("retrieve friends failed! \(error)")
            }
        }
        return Friend()
    }
    mutating func update() {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let storageFilePath = dir.appendingPathComponent(Friend.key)
            print("Update data from friends storage filepath: \(storageFilePath)")
            do {
                let jsonData = try Data(contentsOf: storageFilePath)
                let friend = try JSONDecoder().decode(Friend.self, from: jsonData)
                self.friends = friend.friends
            }
            catch {
                print("Update friends failed! \(error)")
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

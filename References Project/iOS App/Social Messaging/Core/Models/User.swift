//
//  User.swift
//  MyMapKit
//
//  Created by Vũ Quý Đạt  on 27/12/2020.
//

import Foundation

struct ResolveUserSignUp: Decodable {
    let id: UUID
    let name: String
    let username: String
    let email: String?
    let join: Date?
    let phone: String?
    let birth: Date?
    let siwaIdentifier: String?
    let avatar: String?
    let password: String?
    let country: String?
    let gender: Gender?
}

struct User: Codable {
    let id: UUID
    let name: String
    let username: String
    let email: String?
    let join: Date?
    let phone: String?
    let birth: Date?
    let siwaIdentifier: String?
    let avatar: String?
    let password: String?
    let country: String?
    let gender: Gender?
}

struct ResolveMapping: Codable {
    let id: UUID
    let user: ResolveUUID
}
struct ResolveUUID: Codable {
    let id: UUID
}

struct ChatBox: Codable {
    let id: UUID
    let name: String?
    let avatar: String?
    var mappings: [ResolveMapping] = []
    var messages: [WebSocketMessage] = []
}

struct WebSocketMessage: Codable {
    let id: UUID
    let chatBox: ResolveUUID
    let message: String
    let sender: UUID
    let createdAt: Date
}

struct WebSocketMessageCompose: Encodable {
    let chatBox: UUID
    let message: String
    let sender: UUID
}

struct PrivateUserData: Codable {
    let email: String?
    let dob: String?
    let block: [String]
    let gender: Gender?
    let phoneNumber: String?
}

struct SignUpUserPost: Codable {
    var name: String
    var lastName: String?
    var username: String
    var password: String
    var gender: Gender?
    var phoneNumber: String?
    var email: String?
    var dob: String?
    var city: String?
    var country: String?
    var defaultAvartar: DefaultAvartar?
    var bio: String?
    var idDevice: String?
}



// MARK: - Enumeration.
enum PrivacyType: Int, Codable {
    case publicState, privateState
}

enum Gender: Int, Codable {
    case male, female, other
}

enum DefaultAvartar: Int, Codable {
    case nonee, engineer, pianist, male, female, other
}


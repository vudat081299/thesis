//
//  AuthenticatedUser.swift
//  VegaPunk
//
//  Created by Dat Vu on 08/01/2023.
//

import Foundation
import Alamofire

var userDataGlobal = AuthenticatedUser.retrieve()

struct AuthenticatedUser {
    var userInformation: User?
    var userId: UUID?
    var token: String?
    var mappingId: UUID?
    var username: String?
    var password: String?
    
    // NetWork configure
    var domain: String? /// ex: http://192.168.1.168:8080/
    var ip: String?
    var port: String?
}

struct Credential {
    var username: String
    var password: String
}

struct NetworkConfigure {
    var domain: String
    var ip: String
    var port: String
}

// MARK: - Apply Codable
extension AuthenticatedUser: Codable {
    enum Key: String, CodingKey {
        case userInformation
        case userId
        case token
        case mappingId
        case username
        case password
        
        case domain
        case ip
        case port
    }
    
    
    // MARK: - Initializations
    init(_ credential: Credential) {
        self.username = credential.username
        self.password = credential.password
    }
    
    init(_ token: Token) {
        self.userId = token.user.id
        self.token = token.value
    }
    
    init(_ networkConfigure: NetworkConfigure) {
        self.domain = networkConfigure.domain
        self.ip = networkConfigure.ip
        self.port = networkConfigure.port
    }
    
    init(_ userInformation: User) {
        self.userId = userInformation.id
        self.username = userInformation.username
        self.userInformation = userInformation
    }
    
    
    
    // MARK: - Conform to Codable
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        userInformation = try container.decode(User?.self, forKey: .userInformation)
        userId = try container.decode(UUID?.self, forKey: .userId)
        token = try container.decode(String?.self, forKey: .token)
        mappingId = try container.decode(UUID?.self, forKey: .mappingId)
        username = try container.decode(String?.self, forKey: .username)
        password = try container.decode(String?.self, forKey: .password)
        
        domain = try container.decode(String?.self, forKey: .domain)
        ip = try container.decode(String?.self, forKey: .ip)
        port = try container.decode(String?.self, forKey: .port)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(userInformation, forKey: .userInformation)
        try container.encode(userId, forKey: .userId)
        try container.encode(token, forKey: .token)
        try container.encode(mappingId, forKey: .mappingId)
        try container.encode(username, forKey: .username)
        try container.encode(password, forKey: .password)
        
        try container.encode(domain, forKey: .domain)
        try container.encode(ip, forKey: .ip)
        try container.encode(port, forKey: .port)
    }
}


// MARK: - Data handler
extension AuthenticatedUser {
    static var key: String {
        get {
            return "Authenticated_User_SAVING_KEY"
        }
    }
    
    static func store(credential: Credential? = nil,
                      token: Token? = nil,
                      networkConfigure: NetworkConfigure? = nil,
                      userInformation: User? = nil
    ) -> FunctionResult {
        // Update existed UserData
        if let existedUserData = retrieve() {
            var user = existedUserData
            let existedUserData = retrieve()
            if let credential = credential {
                user.username = credential.username
                user.password = credential.password
            }
            if let token = token {
                user.userId = token.user.id
                user.token = token.value
            }
            if let networkConfigure = networkConfigure {
                user.domain = networkConfigure.domain
                user.ip = networkConfigure.ip
                user.port = networkConfigure.port
            }
            if let userInformation = userInformation {
                user.userId = userInformation.id
                user.username = userInformation.username
                user.userInformation = userInformation
            }
            return user.store()
        }
        
        // Create and store
        if let token = token {
            return AuthenticatedUser(token).store()
        }
        if let credential = credential {
            return AuthenticatedUser(credential).store()
        }
        if let userInformation = userInformation {
            return AuthenticatedUser(userInformation).store()
        }
        return .failure
    }
    static func retrieve() -> AuthenticatedUser? {
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                return try PropertyListDecoder().decode(AuthenticatedUser?.self, from: data)
            } catch {
                print("Retrieve UserData object failed!")
            }
        }
        return nil
    }
    func update() {
        if let data = UserDefaults.standard.data(forKey: AuthenticatedUser.key) {
            do {
                if let userData = try PropertyListDecoder().decode(AuthenticatedUser?.self, from: data) {
                    userDataGlobal = userData
                }
            } catch {
                print("Retrieve UserData object failed!")
            }
        }
    }
    func store() -> FunctionResult {
        do {
            let userData = try PropertyListEncoder().encode(self)
            UserDefaults.standard.set(userData, forKey: AuthenticatedUser.key)
            self.update()
            return .success
        } catch {
            print("Error when saving UserData object!")
            return .failure
        }
    }
}



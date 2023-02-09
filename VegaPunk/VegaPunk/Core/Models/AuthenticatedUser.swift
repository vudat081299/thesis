//
//  AuthenticatedUser.swift
//  VegaPunk
//
//  Created by Dat Vu on 08/01/2023.
//

import Foundation
import Alamofire


// MARK: - Definition
struct AuthenticatedUser {
    var credential: Credential?
    var token: Token?
    var data: User?
    /// Network configure
    var networkConfig: NetworkConfig?
}

struct Credential: Codable {
    var username: String
    var password: String
}

struct NetworkConfig: Codable {
    /// ex: http://192.168.1.168:8080/
    var domain: String
    var ip: String
    var port: String
}


// MARK: - Apply Codable
extension AuthenticatedUser: Codable {
    enum Key: String, CodingKey {
        case credential
        case token
        case data
        case networkConfig
    }
    
    
    // MARK: - Initializations
    init(_ credential: Credential) {
        self.data = User(username: credential.username, password: credential.password)
    }
    
    init(_ token: Token) {
        self.token = token
        self.data = User(id: token.user.id, token: token)
    }
    
    init(_ data: User) {
        self.data = data
        if let token = data.token {
            self.token = token
        }
    }
    
    init(_ networkConfig: NetworkConfig) {
        self.networkConfig = networkConfig
    }
    
    
    // MARK: - Conform to Codable
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        credential = try container.decode(Credential?.self, forKey: .credential)
        token = try container.decode(Token?.self, forKey: .token)
        data = try container.decode(User?.self, forKey: .data)
        networkConfig = try container.decode(NetworkConfig?.self, forKey: .networkConfig)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(credential, forKey: .credential)
        try container.encode(token, forKey: .token)
        try container.encode(data, forKey: .data)
        try container.encode(networkConfig, forKey: .networkConfig)
    }
}


// MARK: - Data handler
extension AuthenticatedUser: Storing {
    static func store(credential: Credential? = nil,
                      token: Token? = nil,
                      networkConfig: NetworkConfig? = nil,
                      data: User? = nil
    ) {
        // Update existed UserData
        if var user = retrieve() {
            if let credential = credential {
                user.credential = credential
                if var data = user.data {
                    data.username = credential.username
                    data.password = credential.password
                }
            }
            if let token = token {
                user.token = token
                if var data = user.data {
                    data.token = token
                }
            }
            if let data = data {
                user.data = data
            }
            if let networkConfig = networkConfig {
                user.networkConfig = networkConfig
            }
            user.store()
            return
        }
        
        // Create and store
        if let credential = credential {
            return AuthenticatedUser(credential).store()
        }
        if let token = token {
            return AuthenticatedUser(token).store()
        }
        if let networkConfig = networkConfig {
            return AuthenticatedUser(networkConfig).store()
        }
        if let data = data {
            return AuthenticatedUser(data).store()
        }
    }
    
    
    func store() {
        do {
            let userData = try PropertyListEncoder().encode(self)
            UserDefaults.standard.set(userData, forKey: UserDefaults.Keys.authenticatedUser.rawValue)
        } catch {
            print("Error when saving AuthenticatedUser object!")
        }
    }
    static func retrieve() -> AuthenticatedUser? {
        if let data = UserDefaults.standard.data(forKey: UserDefaults.Keys.authenticatedUser.rawValue) {
            do {
                let user = try PropertyListDecoder().decode(AuthenticatedUser?.self, from: data)
                return user
            } catch {
                print("Retrieve AuthenticatedUser object failed!")
            }
        }
        return nil
    }
    static func remove() {
        UserDefaults.standard.removeObject(forKey: UserDefaults.Keys.authenticatedUser.rawValue)
    }
}



//
//  Auth.swift
//  Social Messaging
//
//  Created by Vũ Quý Đạt  on 24/12/2020.
//

import UIKit
import Alamofire

final class AuthenticationService {
    
    // MARK: - Network configuration
    /// Basic auth username password
    static let BASIC_AUTH_USERNAME = "admin"
    static let BASIC_AUTH_PASSWORD = "password"
    
    
    
    // MARK: - My private data
    static var token: String? {
        get {
            UserDefaults.standard.string(forKey: MY_TOKEN_KEY)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: MY_TOKEN_KEY)
        }
    }
    static var myInformations: User? {
        get {
            if let data = UserDefaults.standard.object(forKey: MY_INFORMATION_KEY) as? Data {
                if let user = try? JSONDecoder().decode(User.self, from: data) {
                    return user
                }
            }
            return nil
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: MY_INFORMATION_KEY)
            }
        }
    }
    static var myMappingId: String? {
        get {
            UserDefaults.standard.string(forKey: MY_MAPPING_KEY)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: MY_MAPPING_KEY)
        }
    }
    static var myUsername: String? {
        get {
            UserDefaults.standard.string(forKey: MY_USERNAME_KEY) ?? "dat1"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: MY_USERNAME_KEY)
        }
    }
    static var myPassword: String? {
        get {
            UserDefaults.standard.string(forKey: MY_PASSWORD_KEY) ?? "dat1"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: MY_PASSWORD_KEY)
        }
    }
    
    
    
    // MARK: - Methods
    // Y+74oy3Pjebhbi0zOihTPw==
    static func signIn() {
        guard let username = myUsername, let password = myPassword else { return }
        let headers: HTTPHeaders = [.authorization(username: username, password: password)]
        AF.request("\(baseURL())/login", method: .post, headers: headers)
            .responseDecodable(of: Token.self) { response in
                switch response.result {
                case .success(let structuredToken):
                    token = structuredToken.value
                    break
                case .failure:
                    break
                }
            }
    }
    static func signUp() {
        AF.request("\(baseURL())", method: .post)
            .responseDecodable(of: User.self) { response in
                switch response.result {
                case .success(let user):
                    myInformations = user
                    getMyMapping()
                    break
                case .failure:
                    break
                }
            }
    }
    static func getMyMapping() {
        guard let user = myInformations else { return }
        AF.request("\(baseURL())/\(user.id.uuidString)/mapping")
            .responseDecodable(of: ResolveMapping.self) { response in
                switch response.result {
                case .success(let resolvedMapping):
                    myMappingId = resolvedMapping.id.uuidString
                    break
                case .failure:
                    break
                }
            }
    }
}

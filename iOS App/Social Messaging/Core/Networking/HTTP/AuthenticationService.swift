//
//  Auth.swift
//  Social Messaging
//
//  Created by Vũ Quý Đạt  on 24/12/2020.
//

import UIKit
import Alamofire

class AuthenticationService {
    // MARK: - Saved data
    static var token: String? {
        get {
            return UserDefaults.standard.string(forKey: TOKEN_KEY)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: TOKEN_KEY)
        }
    }
    
    static var user: User? {
        get {
            if let savedUserContent = UserDefaults.standard.object(forKey: USER_KEY) as? Data {
                if let user = try? JSONDecoder().decode(User.self, from: savedUserContent) {
                    return user
                }
            }
            return nil
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: USER_KEY)
            }
        }
    }
    
    static var mappingId: String? {
        get {
            return UserDefaults.standard.string(forKey: MAPPING_KEY)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: MAPPING_KEY)
        }
    }
    static var groupRoute = "api/users"
    
    // MARK: - API
    static func signIn() {
        AF.request("\(requestProtocol)://\(ip):\(port)/\(groupRoute)/login")
            .authenticate(username: username, password: password)
            .responseDecodable(of: Token.self) { response in
                switch response.result {
                case .success(let token):
                    AuthenticationService.token = token.value
                    break
                case .failure:
                    break
                }
            }
    }
    
    static func signUp() {
        AF.request("\(requestProtocol)://\(ip):\(port)/\(groupRoute)", method: .post)
            .responseDecodable(of: User.self) { response in
                switch response.result {
                case .success(let user):
                    self.user = user
                    getMyMapping()
                    break
                case .failure:
                    break
                }
            }
    }
    
    static func getMyMapping() {
        struct ResolveMapping: Decodable {
            let id: UUID
            let user: ResolveUserFromMapping
        }
        struct ResolveUserFromMapping: Decodable {
            let id: UUID
        }
        guard let user = user else { return }
        AF.request("\(requestProtocol)://\(ip):\(port)/\(groupRoute)/\(user.id.uuidString)/mapping")
            .responseDecodable(of: ResolveMapping.self) { response in
                switch response.result {
                case .success(let resolvedMapping):
                    self.mappingId = resolvedMapping.id.uuidString
                    break
                case .failure:
                    break
                }
            }
    }
}

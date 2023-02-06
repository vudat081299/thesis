//
//  ResourceRequest.swift
//  Social Messaging
//
//  Created by Vũ Quý Đạt  on 11/12/2020.
//

import Foundation
import Alamofire

// MARK: - Configuration
let username = "admin"
let password = "password"
let requestProtocol = "http"
var ip: String? {
    get {
        return UserDefaults.standard.string(forKey: IP_KEY) ?? "192.168.1.25"
    }
    set {
        UserDefaults.standard.set(newValue, forKey: IP_KEY)
    }
}
var port: String? {
    get {
        return UserDefaults.standard.string(forKey: PORT_KEY) ?? "8080"
    }
    set {
        UserDefaults.standard.set(newValue, forKey: PORT_KEY)
    }
}
var domain: String? {
    get {
        return UserDefaults.standard.string(forKey: DOMAIN_KEY) ?? "192.168.1.25:8080"
    }
    set {
        UserDefaults.standard.set(newValue, forKey: DOMAIN_KEY)
        let endIndexOfIp = newValue!.firstIndex(of: Character(":"))
        if let index = endIndexOfIp {
            let startIndexOfPort = newValue!.index(index, offsetBy: 1)
            if (newValue!.startIndex < index && startIndexOfPort < newValue!.endIndex) {
                let ipSubString = newValue![newValue!.startIndex..<index]
                let portSubString = newValue![startIndexOfPort..<newValue!.endIndex]
                ip = String(ipSubString)
                port = String(portSubString)
            }
            print("Network configuration ip:\(ip) \nport:\(port) \ndomain:\(domain)")
        }
    }
}
var baseURL: String {
    return "\(requestProtocol)://\(domain)/api/"
}



// MARK: - RequestService
class RequestService {
    
    static let mappingGroupRoute = "api/mappings"
    static let chatBoxGroupRoute = "api/chatBoxes"
    
    static var friends: [User] {
        get {
            if let savedFriendsData = UserDefaults.standard.object(forKey: ALL_USERS_KEY) as? Data {
                if let friends = try? JSONDecoder().decode([User].self, from: savedFriendsData) {
                    return friends
                }
            }
            return []
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: ALL_USERS_KEY)
            }
        }
    }
    static var userMappingMap: [UUID: UUID] {
        get {
            if let savedMap = UserDefaults.standard.object(forKey: USER_MAPPING_MAP_KEY) as? Data {
                if let map = try? JSONDecoder().decode([UUID: UUID].self, from: savedMap) {
                    return map
                }
            }
            return [:]
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: USER_MAPPING_MAP_KEY)
            }
        }
    }
    static var chatBoxesMap: [UUID: ChatBox] {
        get {
            if let savedChatBoxesMapData = UserDefaults.standard.object(forKey: MY_CHATBOXES_MAP_KEY) as? Data {
                if let chatBoxesMap = try? JSONDecoder().decode([UUID: ChatBox].self, from: savedChatBoxesMapData) {
                    return chatBoxesMap
                    
                }
            }
            return [:]
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: MY_CHATBOXES_MAP_KEY)
            }
        }
    }
    static var chatBoxes: [ChatBox] {
        get {
            if let savedChatBoxesData = UserDefaults.standard.object(forKey: MY_CHATBOXES_KEY) as? Data {
                if let chatBoxes = try? JSONDecoder().decode([ChatBox].self, from: savedChatBoxesData) {
                    return chatBoxes
                    
                }
            }
            return []
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: MY_CHATBOXES_KEY)
            }
        }
    }
    
    
    
    // MARK: -  User api
    static func getAllUsers() {
        AF.request("\(requestProtocol)://\(ip):\(port)/\(AuthenticationService.groupRoute)")
            .responseDecodable(of: [User].self) { response in
                switch response.result {
                case .success(let users):
                    self.friends = users.filter { $0.id != AuthenticationService.user!.id }
                    break
                case .failure:
                    break
                }
            }
    }
    static func updateUser(_ user: User) {
        var params: Parameters = [:]
        params["id"] = user.id
        params["name"] = user.name
        params["username"] = user.username
        if let email = user.email { params["email"] = email }
        if let join = user.join { params["join"] = join }
        if let phone = user.phone { params["phone"] = phone }
        if let birth = user.birth { params["birth"] = birth }
        if let email = user.email { params["email"] = email }
        if let avatar = user.avatar { params["avatar"] = avatar }
        if let password = user.password { params["password"] = password }
        if let country = user.country { params["country"] = country }
        if let gender = user.gender { params["gender"] = gender }
        
        let headers: HTTPHeaders = [.authorization(bearerToken: AuthenticationService.token!)]
        AF.request("\(requestProtocol)://\(ip):\(port)/\(AuthenticationService.groupRoute)",
                   method: .put,
                   parameters: params,
                   headers: headers)
        .responseDecodable(of: User.self) { response in
            switch response.result {
            case .success(let user):
                AuthenticationService.user = user
                break
            case .failure:
                break
            }
        }
    }
    
    
    
    // MARK: - Mapping
    static func getMyChatBoxes() {
        AF.request("\(requestProtocol)://\(ip):\(port)/\(mappingGroupRoute)/\(AuthenticationService.mappingId!)/chatBoxes")
            .responseDecodable(of: [ChatBox].self) { response in
                switch response.result {
                case .success(let chatBoxes):
                    self.chatBoxes = chatBoxes
                    var dictionaryChatBoxes = [UUID: ChatBox]()
                    chatBoxes.forEach { chatBox in
                        dictionaryChatBoxes[chatBox.id] = chatBox
                    }
                    self.chatBoxesMap = dictionaryChatBoxes
                    break
                case .failure:
                    break
                }
            }
    }
    static func getAllMappings() {
        AF.request("\(requestProtocol)://\(ip):\(port)/\(mappingGroupRoute)")
            .responseDecodable(of: [ResolveMapping].self) { response in
                switch response.result {
                case .success(let mappings):
                    mappings.forEach { mapping in
                        self.userMappingMap[mapping.user.id] = mapping.id
                    }
                    break
                case .failure:
                    break
                }
            }
    }
    static func createChatBoxes(with friendID: UUID) {
        var params: Parameters = [:]
        guard let friendMappingId = self.userMappingMap[friendID] else { return }
        params["mappingIds"] = [AuthenticationService.mappingId!, friendMappingId]
        
        let headers: HTTPHeaders = [.authorization(bearerToken: AuthenticationService.token!)]
        AF.request("\(requestProtocol)://\(ip):\(port)/\(mappingGroupRoute)/\(AuthenticationService.mappingId!)/chatBoxes",
                   method: .post,
                   parameters: params,
                   headers: headers)
        .responseDecodable(of: [ChatBox].self) { response in
            switch response.result {
            case .success:
                break
            case .failure:
                break
            }
        }
    }
    
    
    
    // MARK: - Chat box
    static func getChatBoxMemberMappings(_ chatBoxID: UUID) {
        AF.request("\(requestProtocol)://\(ip):\(port)/\(chatBoxGroupRoute)/\(chatBoxID)/mappings")
            .responseDecodable(of: [ResolveMapping].self) { response in
                switch response.result {
                case .success(let mappings):
                    var tempChatBoxes = self.chatBoxesMap
                    tempChatBoxes[chatBoxID]?.mappings = mappings
                    self.chatBoxesMap = tempChatBoxes
                    break
                case .failure:
                    break
                }
            }
    }
    static func getChatBoxMessage(_ chatBoxID: UUID) {
        AF.request("\(requestProtocol)://\(ip):\(port)/\(chatBoxGroupRoute)/\(chatBoxID)/messages")
            .responseDecodable(of: [WebSocketMessage].self) { response in
                switch response.result {
                case .success(let messages):
                    var tempChatBoxes = self.chatBoxesMap
                    tempChatBoxes[chatBoxID]?.messages = messages
                    self.chatBoxesMap = tempChatBoxes
                    break
                case .failure:
                    break
                }
            }
    }
}

//
//  ResourceRequest.swift
//  Social Messaging
//
//  Created by Vũ Quý Đạt  on 11/12/2020.
//

import Foundation
import Alamofire

let REQUEST_PROTOCOL = "http"
var ip: String? {
    get {
        UserDefaults.standard.string(forKey: IP_KEY) ?? "192.168.1.24"
    }
    set {
        UserDefaults.standard.set(newValue, forKey: IP_KEY)
    }
}
var port: String? {
    get {
        UserDefaults.standard.string(forKey: PORT_KEY) ?? "8080"
    }
    set {
        UserDefaults.standard.set(newValue, forKey: PORT_KEY)
    }
}
var domain: String? {
    get {
        UserDefaults.standard.string(forKey: DOMAIN_KEY) ?? "192.168.1.24:8080"
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
            print("Network configuration ip:\(ip!) \nport:\(port!) \ndomain:\(domain!)")
        }
    }
}

final class RequestService {
    
    // MARK: - User
    static func readAllUsers() {
        AF.request("\(baseURL())")
            .responseDecodable(of: [User].self) { response in
                switch response.result {
                case .success(let users):
                    DataService.friends = users.filter { $0.id != AuthenticationService.myInformations?.id }
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
        if let gender = user.gender?.rawValue { params["gender"] = gender }
        
        let headers: HTTPHeaders = [.authorization(bearerToken: AuthenticationService.token!)]
        AF.request("\(baseURL())",
                   method: .put,
                   parameters: params,
                   headers: headers)
        .responseDecodable(of: User.self) { response in
            switch response.result {
            case .success(let user):
                AuthenticationService.myInformations = user
                break
            case .failure(let error):
                print(error)
                break
            }
        }
    }
    
    
    
    // MARK: - Mapping
    static func readMyChatBoxes() {
        AF.request("\(baseURL(.mappings))/\(AuthenticationService.myMappingId!)/chatBoxes")
            .responseDecodable(of: [ChatBox].self) { response in
                switch response.result {
                case .success(let chatBoxes):
                    DataService.chatBoxes = chatBoxes
                    var dictionaryChatBoxes = [UUID: ChatBox]()
                    chatBoxes.forEach { chatBox in
                        dictionaryChatBoxes[chatBox.id] = chatBox
                    }
                    DataService.idChatBoxMap = dictionaryChatBoxes
                    break
                case .failure:
                    break
                }
            }
    }
    static func readAllMappings() {
        AF.request("\(baseURL(.mappings))")
            .responseDecodable(of: [ResolveMapping].self) { response in
                switch response.result {
                case .success(let mappings):
                    mappings.forEach { mapping in
                        DataService.userIDMappingIdMap[mapping.user.id] = mapping.id
                    }
                    break
                case .failure:
                    break
                }
            }
    }
    static func createChatBoxes(with friendID: UUID) {
        var params: Parameters = [:]
        guard let friendMappingId = DataService.userIDMappingIdMap[friendID] else { return }
        params["mappingIds"] = [AuthenticationService.myMappingId!, friendMappingId]
        
        let headers: HTTPHeaders = [.authorization(bearerToken: AuthenticationService.token!)]
        AF.request("\(baseURL(.mappings))/\(AuthenticationService.myMappingId!)/chatBoxes",
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
    static func readChatBoxMemberMappings(_ chatBoxID: UUID) {
        AF.request("\(baseURL(.chatBoxes))/\(chatBoxID)/mappings")
            .responseDecodable(of: [ResolveMapping].self) { response in
                switch response.result {
                case .success(let mappings):
                    var tempChatBoxes = DataService.idChatBoxMap
                    tempChatBoxes[chatBoxID]?.mappings = mappings
                    DataService.idChatBoxMap = tempChatBoxes
                    break
                case .failure:
                    break
                }
            }
    }
    static func readChatBoxMessage(_ chatBoxID: UUID) {
        AF.request("\(baseURL(.chatBoxes))/\(chatBoxID)/messages")
            .responseDecodable(of: [WebSocketMessage].self) { response in
                switch response.result {
                case .success(let messages):
                    var tempChatBoxes = DataService.idChatBoxMap
                    tempChatBoxes[chatBoxID]?.messages = messages
                    DataService.idChatBoxMap = tempChatBoxes
                    break
                case .failure:
                    break
                }
            }
    }
}

//
//  RouteCoodinator.swift
//  VegaPunk
//
//  Created by Dat Vu on 08/01/2023.
//

import Foundation
import Alamofire

enum RouteCoordinator: String {
    case user = "api/users/"
    case mapping = "api/mappings/"
    case chatbox = "api/chatBoxes/"
    case message = "api/messages/"
    case pivot = "api/mapping/pivot/"
    case file = "api/files/"
    case websocket = "api/messages/listen/"
    case none = ""
    
    func url() -> String? {
        if self == .websocket {
            let networkConfig = AuthenticatedUser.retrieve()?.networkConfig
            let domain = "ws://\(networkConfig!.ip):\(networkConfig!.port)/"
            return domain + self.rawValue
        }
        if let domain = AuthenticatedUser.retrieve()?.networkConfig?.domain {
            return domain + self.rawValue
        }
        return "http://\(configureIp):8080/" + self.rawValue
    }
}

enum Route: CaseIterable {
    case signUp
    case signIn
    case getAllUsers
    case updateUser
//    case getAllMappings // ------> mappingRoute
    case getMyChatBoxes // ------> mappingRoute
    case createChatBox // ------> mappingRoute /// Different: this api is processed in MappingsController on Server
    case getMemberInChatBox // ------>
    case getMessagesOfChatBox
    case addMemberIntoChatBox
    case deleteMemberFromChatBox // ------>
    case removeChatBox
    case createMessage
    case getLastestUpdatedTimeStampChatBox
    case getMessagesFromTimeChatBox
    case getAllMappingPivots // ------>
    case uploadFile
    case downloadFile
}

struct QueryBuilder {
    static let userRoute = RouteCoordinator.user.url()
    static let chatBoxRoute = RouteCoordinator.chatbox.url()
    static let messageRoute = RouteCoordinator.message.url()
    static let pivotRoute = RouteCoordinator.pivot.url()
    static let fileRoute = RouteCoordinator.file.url()
    
    static func queryInfomation(_ route: Route, _ parammeters: [String: String] = [:]) -> QueryInformation? {
        let userId = (AuthenticatedUser.retrieve()?.data?.id?.uuidString) ?? ""
        switch route {
            // User
        case .signUp: return QueryInformation(httpMethod: .post, url: userRoute!, encodableType: User.self, decodableType: User.self)
        case .signIn: return QueryInformation(httpMethod: .post, url: userRoute! + "login", decodableType: Token.self)
        case .getAllUsers: return QueryInformation(url: userRoute!, decodableType: [User].self)
        case .updateUser: return QueryInformation(httpMethod: .put, url: userRoute!, encodableType: User.self, decodableType: User.self)
            
            // Pivot
        case .getAllMappingPivots: return QueryInformation(url: pivotRoute!, decodableType: [ChatboxMember.Resolve].self)
            
            // Chatbox
        case .createChatBox: return QueryInformation(httpMethod: .post, url: userRoute! + "chatBox/create")
        case .getMyChatBoxes: return QueryInformation(url: userRoute! + userId + "/chatBoxes", decodableType: [Chatbox].self)
        case .getMemberInChatBox:
            guard let chatBoxId = parammeters["chatBoxId"] else { return nil }
            return QueryInformation(url: chatBoxRoute! + chatBoxId + "/mappings", decodableType: [User].self)
        case .getMessagesOfChatBox:
            guard let chatBoxId = parammeters["chatBoxId"] else { return nil }
            return QueryInformation(url: chatBoxRoute! + chatBoxId + "/messages", decodableType: [ChatboxMessage.Resolve].self)
        case .removeChatBox:
            guard let chatBoxId = parammeters["chatBoxId"] else { return nil }
            return QueryInformation(httpMethod: .delete, url: chatBoxRoute! + chatBoxId)
        case .addMemberIntoChatBox:
            guard let chatBoxId = parammeters["chatBoxId"] else { return nil }
            return QueryInformation(httpMethod: .post, url: chatBoxRoute! + chatBoxId + "/members")
        case .deleteMemberFromChatBox:
            guard let chatBoxId = parammeters["chatBoxId"] else { return nil }
            guard let mappingId = parammeters["mappingId"] else { return nil }
            return QueryInformation(httpMethod: .delete, url: chatBoxRoute! + chatBoxId + "/members/" + mappingId)
            
            // Message
        case .createMessage: return QueryInformation(httpMethod: .post, url: messageRoute!)
        case .getLastestUpdatedTimeStampChatBox:
            guard let chatBoxId = parammeters["chatBoxId"] else { return nil }
            return QueryInformation(url: messageRoute! + chatBoxId + "/time", decodableType: String.self)
        case .getMessagesFromTimeChatBox:
            guard let chatBoxId = parammeters["chatBoxId"],
                  let time = parammeters["time"]
            else { return nil }
            return QueryInformation(url: messageRoute! + "messages/" + chatBoxId + "/" + time, decodableType: [ChatboxMessage.Resolve].self)
            
            // File
        case .uploadFile: return QueryInformation(httpMethod: .post, url: fileRoute!, decodableType: String.self)
        case .downloadFile: return QueryInformation(httpMethod: .post, url: fileRoute!, decodableType: String.self)
            
        }
    }
}

struct QueryInformation {
    let httpMethod: HTTPMethod
    let url: String
    let encodableType: Codable.Type?
    let decodableType: Codable.Type?
    
    init(httpMethod: HTTPMethod = .get, url: String, encodableType: Codable.Type? = nil, decodableType: Codable.Type? = nil) {
        self.httpMethod = httpMethod
        self.url = url
        self.encodableType = encodableType.self
        self.decodableType = decodableType.self
    }
    
    func genUrl() -> String {
        print("Request: " + url)
        return url
    }
}

//class QueryFactory {
//    let userRoute = RouteCoordinator.user.url()
//    let mappingRoute = RouteCoordinator.mapping.url()
//    let chatBoxRoute = RouteCoordinator.chatbox.url()
//    let messageRoute = RouteCoordinator.message.url()
//    let pivotRoute = RouteCoordinator.pivot.url()
//    let fileRoute = RouteCoordinator.file.url()
//    var userMappingId: String {
//        get {
//            return (AuthenticatedUser.retrieve()?.data?.mappingId?.uuidString) ?? ""
//        }
//    }
//    static let signup = QueryInformation(httpMethod: .post, url: RouteCoordinator.user.url(), encodableType: User.self, decodableType: User.self)
//
//}
//
//struct QueryEngine<E, D> {
//    let httpMethod: HTTPMethod
//    let url: String?
//    let encodableType: E.Type?
//    let decodableType: D.Type?
//
//    init(httpMethod: HTTPMethod = .get, url: String?, parammeters: [String: String] = [:], encodableType: E.Type? = nil, decodableType: D.Type? = nil) {
//        self.httpMethod = httpMethod
//        self.url = url
//        self.encodableType = encodableType.self
//        self.decodableType = decodableType.self
//    }
//
//    func genUrl() -> String? {
//        print("Request: " + url)
//        return url
//    }
//}

//struct QueryInformation<T> {
//    let httpMethod: HTTPMethod
//    let url: String
//    let encodableType: T.Type?
//    let decodableType: T.Type?
//
//    init(httpMethod: HTTPMethod = .get, url: String, encodableType: T.Type? = nil, decodableType: T.Type? = nil) {
//        self.httpMethod = httpMethod
//        self.url = url
//        self.encodableType = encodableType.self
//        self.decodableType = decodableType.self
//    }
//
//    func genUrl() -> String {
//        print("Request: " + url)
//        return url
//    }
//}

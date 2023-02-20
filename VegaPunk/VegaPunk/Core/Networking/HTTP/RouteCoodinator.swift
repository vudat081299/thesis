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
//    case getUserMapping
    case updateUser
    case getAllMappings
    case getMyChatBoxes
    case createChatBox /// Different: this api is processed in MappingsController on Server
    case getMemberInChatBox
    case getMessagesOfChatBox
//    case createChatBox2 /// Different: this api is processed in ChatBoxesController on Server
    case removeChatBox
    case createMessage
    case getLastestUpdatedTimeStampChatBox
    case getMessagesFromTimeChatBox
    case getAllMappingPivots
    case uploadFile
    case downloadFile
}

struct QueryBuilder {
    static let userRoute = RouteCoordinator.user.url()
    static let mappingRoute = RouteCoordinator.mapping.url()
    static let chatBoxRoute = RouteCoordinator.chatbox.url()
    static let messageRoute = RouteCoordinator.message.url()
    static let pivotRoute = RouteCoordinator.pivot.url()
    static let fileRoute = RouteCoordinator.file.url()
    
    static func queryInfomation(_ route: Route, _ parammeters: [String: String] = [:]) -> QueryInformation? {
        let userMappingId = (AuthenticatedUser.retrieve()?.data?.mappingId?.uuidString) ?? ""
        switch route {
        case .signUp: return QueryInformation(httpMethod: .post, url: userRoute!, encodableType: User.self, decodableType: User.self)
        case .signIn: return QueryInformation(httpMethod: .post, url: userRoute! + "login", decodableType: Token.self)
        case .getAllUsers: return QueryInformation(url: userRoute!, decodableType: [User].self)
//        case .getUserMapping: return QueryInformation(url: userRoute! + (AuthenticatedUser.retrieve()?.data?.id?.uuidString)! + "/mapping", decodableType: Mapping.Resolve.self)
        case .updateUser: return QueryInformation(httpMethod: .put, url: userRoute!, encodableType: User.self, decodableType: User.self)
        case .getAllMappings: return QueryInformation(url: mappingRoute!, decodableType: [Mapping.Resolve].self)
        case .getMyChatBoxes: return QueryInformation(url: mappingRoute! + userMappingId + "/chatBoxes", decodableType: [ChatBox].self)
        case .createChatBox: return QueryInformation(httpMethod: .post, url: mappingRoute! + "chatBox/create")
        case .getMemberInChatBox:
            guard let chatBoxId = parammeters["chatBoxId"] else { return nil }
            return QueryInformation(url: chatBoxRoute! + chatBoxId + "/mappings", decodableType: [Mapping.Resolve].self)
        case .getMessagesOfChatBox:
            guard let chatBoxId = parammeters["chatBoxId"] else { return nil }
            return QueryInformation(url: chatBoxRoute! + chatBoxId + "/messages", decodableType: [ChatBoxMessage.Resolve].self)
//        case .createChatBox2: return QueryInformation(httpMethod: .post, url: chatBoxRoute! + "chatBox/create")
        case .removeChatBox:
            guard let chatBoxId = parammeters["chatBoxId"] else { return nil }
            return QueryInformation(httpMethod: .delete, url: chatBoxRoute! + chatBoxId)
        case .createMessage: return QueryInformation(httpMethod: .post, url: messageRoute!)
        case .getLastestUpdatedTimeStampChatBox:
            guard let chatBoxId = parammeters["chatBoxId"] else { return nil }
            return QueryInformation(url: messageRoute! + chatBoxId + "/time", decodableType: String.self)
        case .getMessagesFromTimeChatBox:
            guard let chatBoxId = parammeters["chatBoxId"],
                  let time = parammeters["time"]
            else { return nil }
            return QueryInformation(url: messageRoute! + "messages/" + chatBoxId + "/" + time, decodableType: [ChatBoxMessage.Resolve].self)
        case .getAllMappingPivots: return QueryInformation(url: pivotRoute!, decodableType: [MappingChatBoxPivot.Resolve].self)
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

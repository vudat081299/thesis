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
    case none = ""
    
    func url() -> String? {
        if let domain = AuthenticatedUser.retrieve()?.domain {
            return domain + self.rawValue
        }
        return "http://192.168.1.24:8080/" + self.rawValue
    }
}

enum Route: CaseIterable {
    case signUp
    case signIn
    case getAllUsers
    case getUserMapping
    case updateUser
    
    case getAllMappings
    case getMyChatBoxes
    case createChatBox /// Different: this api is processed in MappingsController on Server
    
    case createChatBox2 /// Different: this api is processed in ChatBoxesController on Server
    case getMemberInChatBox
    case removeChatBox
    case getMessagesOfChatBox
    
    case createMessage
    
    case getAllMappingPivots
}

struct Queries {
    let userRoute = RouteCoordinator.user.url()
    let mappingRoute = RouteCoordinator.mapping.url()
    let chatBoxRoute = RouteCoordinator.chatbox.url()
    let messageRoute = RouteCoordinator.message.url()
    let pivotRoute = RouteCoordinator.pivot.url()
    
    func queryInfomation(_ route: Route, _ chatBoxId: UUID? = nil) -> QueryInformation? {
        switch route {
        case .getAllUsers: return QueryInformation(url: userRoute!, decodableType: [User].self)
        case .getUserMapping: return QueryInformation(url: userRoute! + (AuthenticatedUser.retrieve()?.userId!.uuidString)! + "/mapping", decodableType: ResolveMapping.self)
        case .signUp: return QueryInformation(httpMethod: .post, url: userRoute!, encodableType: User.self, decodableType: User.self)
        case .signIn: return QueryInformation(httpMethod: .post, url: userRoute! + "login", decodableType: Token.self)
        case .updateUser: return QueryInformation(httpMethod: .put, url: userRoute!, encodableType: User.self, decodableType: User.self)
            
        case .getAllMappings: return QueryInformation(url: mappingRoute!, decodableType: [ResolveMapping].self)
        case .getMyChatBoxes: return QueryInformation(url: mappingRoute! + (AuthenticatedUser.retrieve()?
            .mappingId!.uuidString)! + "/chatBoxes", decodableType: [ChatBox].self)
        case .createChatBox: return QueryInformation(httpMethod: .post, url: mappingRoute! + "chatBox/create")
            
        case .getMemberInChatBox:
            guard let chatBoxId = chatBoxId else { return nil }
            return QueryInformation(url: chatBoxRoute! + chatBoxId.uuidString + "/mappings", decodableType: [ResolveMapping].self)
        case .getMessagesOfChatBox:
            guard let chatBoxId = chatBoxId else { return nil }
            return QueryInformation(url: chatBoxRoute! + chatBoxId.uuidString + "/messages", decodableType: [WebSocketMessage].self)
        case .createChatBox2: return QueryInformation(httpMethod: .post, url: chatBoxRoute! + "chatBox/create")
        case .removeChatBox:
            guard let chatBoxId = chatBoxId else { return nil }
            return QueryInformation(httpMethod: .delete, url: chatBoxRoute! + chatBoxId.uuidString)
            
        case .createMessage: return QueryInformation(httpMethod: .post, url: messageRoute!)
            
        case .getAllMappingPivots: return QueryInformation(url: pivotRoute!, decodableType: [ResolvePivot].self)
        }
    }
}

struct QueryInformation {
    let httpMethod: HTTPMethod
    let url: String
    let encodableType: Codable.Type?
    let decodableType: Codable.Type?
    
//    init(httpMethod: HTTPMethod = .get, url: String, decodableType: T.Type? = T.self, codableType: T.Type? = T.self) {
//        self.httpMethod = httpMethod
//        self.url = url
//        self.decodableType = decodableType.self!
//        self.codableType = codableType.self!
//    }
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

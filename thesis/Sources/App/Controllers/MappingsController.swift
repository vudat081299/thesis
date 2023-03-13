//
//  MappingsController.swift
//  
//
//  Created by Dat Vu on 28/11/2022.
//

import Vapor
import Fluent

struct MappingsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let mappingsRoutes = routes.grouped("api", "mappings")
        
        //    mappingsRoutes.get("sorted", use: sortedHandler)
        //    mappingsRoutes.get("search", use: searchHandler)
//        mappingsRoutes.get(use: getAllHandler)
//        mappingsRoutes.get(":mappingId", use: getHandler)
//        mappingsRoutes.get("first", use: getFirstHandler)
//        mappingsRoutes.get(":mappingId", "user", use: getUserHandler)
//        mappingsRoutes.get(":mappingId", "chatBoxes", use: getchatBoxesHandler)
        
        /// Auth
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = mappingsRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
//        tokenAuthGroup.post(use: createHandler)
//        tokenAuthGroup.post("chatBox", "create", use: addchatBoxesHandler)
//        tokenAuthGroup.post("add", "members", ":chatBoxId", use: addMembersIntoChatBoxesHandler)
        
//        tokenAuthGroup.put(":mappingId", use: updateHandler)
//        tokenAuthGroup.delete(":mappingId", "chatBoxes", ":chatBoxId", use: deleteChatBoxesHandler)
//        tokenAuthGroup.delete(":mappingId", use: deleteHandler)
    }
    
    
    // MARK: - Create
//    func createHandler(_ req: Request) async throws -> Mapping {
//        let user = try req.auth.require(User.self)
//        let mapping = try Mapping(userID: user.requireID())
//        try await mapping.save(on: req.db)
//        return mapping
//    }
    
    
    // MARK: - Get
    ///
    //  func searchHandler(_ req: Request) throws -> EventLoopFuture<[Mapping]> {
    //    guard let searchTerm = req
    //      .query[String.self, at: "term"] else {
    //      throw Abort(.badRequest)
    //    }
    //    return Mapping.query(on: req.db).group(.or) { or in
    //      or.filter(\.$short == searchTerm)
    //      or.filter(\.$long == searchTerm)
    //    }.all()
    //  }
    ///
    //  func sortedHandler(_ req: Request) -> EventLoopFuture<[Mapping]> {
    //    return Mapping.query(on: req.db).sort(\.$short, .ascending).all()
    //  }
    
//    func getchatBoxesHandler(_ req: Request) async throws -> [Chatbox] {
//        print("handler 😀😀😀: \(#function), line: \(#line)")
//        guard let mapping = try await Mapping.find(req.parameters.get("mappingId"), on: req.db) else {
//            throw Abort(.notFound)
//        }
//        return try await mapping.$chatBoxes.query(on: req.db).all()
//    }
//    func getFirstHandler(_ req: Request) async throws -> Mapping {
//        guard let mapping = try await Mapping.query(on: req.db).first() else {
//            throw Abort(.notFound)
//        }
//        return mapping
//    }
//    func getUserHandler(_ req: Request) async throws -> User.Public {
//        guard let mapping = try await Mapping.find(req.parameters.get("mappingId"), on: req.db) else {
//            throw Abort(.notFound)
//        }
//        let publicUsers = try await mapping.$user.get(on: req.db).convertToPublic()
//        return publicUsers
//    }
//    func getAllHandler(_ req: Request) async throws -> [Mapping] {
//        try await Mapping.query(on: req.db).all()
//    }
//    func getHandler(_ req: Request) async throws -> Mapping {
//        guard let mapping = try await Mapping.find(req.parameters.get("mappingId"), on: req.db) else {
//            throw Abort(.notFound)
//        }
//        return mapping
//    }
    
    
    // MARK: - Post <methods>
//    func addMembersIntoChatBoxesHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
//        struct ResolveAddingMembersIntoChatBox: Codable {
//            let mappingIds: [UUID]
//        }
//        guard let chatBoxId = req.parameters.get("chatBoxId") else {
//            throw Abort(.notFound)
//        }
//        let resolvedModel = try req.content.decode(ResolveAddingMembersIntoChatBox.self)
//        return Chatbox.find(UUID(uuidString: chatBoxId), on: req.db).unwrap(or: Abort(.notFound)).flatMap { chatBox in
//            resolvedModel.mappingIds.map { mappingId in
//                Mapping.find(mappingId, on: req.db)
//                    .unwrap(or: Abort(.notFound))
//                    .flatMap { $0.$chatBoxes.attach(chatBox, on: req.db) }
//            }.flatten(on: req.eventLoop).transform(to: .created)
//        }
//    }
    
    /// Bad code
    //    func addchatBoxesHandlerOld(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
    //        struct ResolveCreateMappingChatBox: Codable {
    //            let mappingIds: [UUID]
    //        }
    //        let updateUserData = try req.content.decode(ResolveCreateMappingChatBox.self)
    //        let chatBox = ChatBox(name: "Friend")
    //        let _ = chatBox.create(on: req.db)
    //        return updateUserData.mappingIds.map { mappingId in
    //            print("handler 😀😀😀: \(#function), line: \(#line), \(mappingId)")
    //            let mappingQuery = Mapping.find(mappingId, on: req.db).unwrap(or: Abort(.notFound))
    //            let chatBoxQuery = ChatBox.find(chatBox.id, on: req.db).unwrap(or: Abort(.notFound))
    //            return mappingQuery.and(chatBoxQuery).flatMap { mapping, chatBox in
    //                mapping.$chatBoxes.attach(chatBox, on: req.db)
    //            }
    //        }.flatten(on: req.eventLoop).transform(to: .created)
    //    }

    /// Optimal code syntax write by vzsg convert to async version
//    func addchatBoxesHandler(_ req: Request) async throws -> HTTPStatus {
//        struct ResolveCreateMappingChatBox: Codable {
//            let mappingIds: [UUID]
//        }
//        let user = try req.auth.require(User.self)
//        let resolvedModel = try req.content.decode(ResolveCreateMappingChatBox.self)
//        let chatBox = Chatbox(name: "New group!")
//        try await chatBox.save(on: req.db)
//        let mappings = try await Dictionary(uniqueKeysWithValues: Mapping.query(on: req.db).all().map { ($0.$user.id, $0.id!) })
//        user.mappingId = mappings[user.id!]
//        let message = Message(sender: user.mappingId!, mediaType: MediaType.notify.rawValue, content: "👋 Hi! I just create this chat box, I'm @\(user.username)!", chatBoxId: chatBox.id!)
//        try await message.save(on: req.db)
//
//        for mappingId in resolvedModel.mappingIds {
//            guard let mapping = try await Mapping.find(mappingId, on: req.db) else {
//                throw Abort(.notFound)
//            }
//            try await mapping.$chatBoxes.attach(chatBox, on: req.db)
//        }
//        let package = WebSocketPackage(type: .chatBox, message: WebSocketPackageMessage(id: nil, createdAt: message.createdAt, sender: user.mappingId, chatBoxId: chatBox.id, mediaType: .text, content: message.content))
//        webSocketManager.send(to: resolvedModel.mappingIds, package: package)
//        return .created
//
//
////        let updateUserData = try req.content.decode(ResolveCreateMappingChatBox.self)
////        let chatBox = ChatBox(name: "Friend")
////        try await chatBox.save(on: req.db)
////
////        updateUserData.mappingIds.map { mappingId in
////            guard let mapping = try Mapping.find(mappingId, on: req.db) else {
////                throw Abort(.notFound)
////            }
////            mapping.$chatBoxes.attach(chatBox, on: req.db)
////        }
////        return .created
//    }
    /// Optimal code syntax write by vzsg
    /// Non async version
//    func addchatBoxesHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
//        struct ResolveCreateMappingChatBox: Codable {
//            let mappingIds: [UUID]
//        }
//        let user = try req.auth.require(User.self)
//
//        let resolvedModel = try req.content.decode(ResolveCreateMappingChatBox.self)
//        let chatBox = ChatBox(name: "Friend")
//
//        return chatBox.save(on: req.db).flatMap {
//            // confuse: - need change to mapping id
////            let message = Message(sender: user.id!, mediaType: MediaType.notify.rawValue, content: "Hi! I just create this chat box, I'm @\(user.username)!", chatBoxId: chatBox.id!)
////            message.save(on: req.db).flatMap {
//                resolvedModel.mappingIds.map { mappingId in
//                    Mapping.find(mappingId, on: req.db)
//                        .unwrap(or: Abort(.notFound))
//                        .flatMap { $0.$chatBoxes.attach(chatBox, on: req.db) }
//                }.flatten(on: req.eventLoop).transform(to: .created)
////            }
//        }
//    }
    
    
    // MARK: - Update
//    func updateHandler(_ req: Request) async throws -> Mapping {
//        let user = try req.auth.require(User.self)
//        let userID = try user.requireID()
//        guard let mapping = try await Mapping.find(req.parameters.get("mappingId"), on: req.db) else {
//            throw Abort(.notFound)
//        }
//        mapping.$user.id = userID
//        try await mapping.save(on: req.db)
//        return mapping
//    }
    
    
    // MARK: - Delete
//    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
//        guard let mapping = try await Mapping.find(req.parameters.get("mappingId"), on: req.db) else {
//            throw Abort(.notFound)
//        }
//        try await mapping.delete(on: req.db)
//        return .noContent
//    }
//    func deleteChatBoxesHandler(_ req: Request) async throws -> HTTPStatus {
//        guard let mappingQuery = try await Mapping.find(req.parameters.get("mappingId"), on: req.db) else {
//            throw Abort(.notFound)
//        }
//        guard let chatBoxQuery = try await Chatbox.find(req.parameters.get("chatBoxId"), on: req.db) else {
//            throw Abort(.notFound)
//        }
//        try await mappingQuery.$chatBoxes.detach(chatBoxQuery, on: req.db)
//        return .noContent
//    }
    
    /// Converting to async
    //    func removechatBoxesHandler(_ req: Request) async throws -> HTTPStatus {
    //        let mappingQuery = Mapping.find(req.parameters.get("mappingId"), on: req.db).unwrap(or: Abort(.notFound))
    //        let chatBoxQuery = ChatBox.find(req.parameters.get("chatBoxId"), on: req.db).unwrap(or: Abort(.notFound))
    //        let a = mappingQuery.and(chatBoxQuery)
    //        a[0].$chatBoxes.detach(a[1], on: req.db)
    //        return .noContent
    //    }
    
    /// EventLoopFuture
    //    func removechatBoxesHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
    //        let mappingQuery = Mapping.find(req.parameters.get("mappingId"), on: req.db).unwrap(or: Abort(.notFound))
    //        let chatBoxQuery = ChatBox.find(req.parameters.get("chatBoxId"), on: req.db).unwrap(or: Abort(.notFound))
    //        return mappingQuery.and(chatBoxQuery).flatMap { mapping, chatBox in
    //            mapping.$chatBoxes.detach(chatBox, on: req.db).transform(to: .noContent)
    //        }
    //    }
    
}

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
        mappingsRoutes.get(use: getAllHandler)
        mappingsRoutes.get(":mappingID", use: getHandler)
        //    mappingsRoutes.get("search", use: searchHandler)
        mappingsRoutes.get("first", use: getFirstHandler)
        //    mappingsRoutes.get("sorted", use: sortedHandler)
        mappingsRoutes.get(":mappingID", "user", use: getUserHandler)
        mappingsRoutes.get(":mappingID", "chatBoxes", use: getchatBoxesHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = mappingsRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.delete(":mappingID", use: deleteHandler)
        tokenAuthGroup.put(":mappingID", use: updateHandler)
        tokenAuthGroup.post("chatBox", "create", use: addchatBoxesHandler)
        tokenAuthGroup.post("add", "members", "chatBox", use: addMembersIntoChatBoxesHandler)
        
        tokenAuthGroup.delete(":mappingID", "chatBoxes", ":chatBoxID", use: removechatBoxesHandler)
    }
    
    func getAllHandler(_ req: Request) async throws -> [Mapping] {
        try await Mapping.query(on: req.db).all()
    }
    
    func createHandler(_ req: Request) async throws -> Mapping {
        let user = try req.auth.require(User.self)
        let mapping = try Mapping(userID: user.requireID())
        try await mapping.save(on: req.db)
        return mapping
    }
    
    func getHandler(_ req: Request) async throws -> Mapping {
        guard let mapping = try await Mapping.find(req.parameters.get("mappingID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return mapping
    }
    
    func updateHandler(_ req: Request) async throws -> Mapping {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        guard let mapping = try await Mapping.find(req.parameters.get("mappingID"), on: req.db) else {
            throw Abort(.notFound)
        }
        mapping.$user.id = userID
        try await mapping.save(on: req.db)
        return mapping
    }
    
    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        guard let mapping = try await Mapping.find(req.parameters.get("mappingID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await mapping.delete(on: req.db)
        return .noContent
    }
    
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
    
    func getFirstHandler(_ req: Request) async throws -> Mapping {
        guard let mapping = try await Mapping.query(on: req.db).first() else {
            throw Abort(.notFound)
        }
        return mapping
    }
    
    //  func sortedHandler(_ req: Request) -> EventLoopFuture<[Mapping]> {
    //    return Mapping.query(on: req.db).sort(\.$short, .ascending).all()
    //  }
    
    func getUserHandler(_ req: Request) async throws -> User.Public {
        guard let mapping = try await Mapping.find(req.parameters.get("mappingID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let publicUsers = try await mapping.$user.get(on: req.db).convertToPublic()
        return publicUsers
    }
    
    func addMembersIntoChatBoxesHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        struct ResolveAddingMembersIntoChatBox: Codable {
            let chatBoxID: UUID
            let mappingIDs: [UUID]
        }
        let resolvedModel = try req.content.decode(ResolveAddingMembersIntoChatBox.self)
        return ChatBox.find(resolvedModel.chatBoxID, on: req.db).unwrap(or: Abort(.notFound)).flatMap { chatBox in
            resolvedModel.mappingIDs.map { mappingID in
                Mapping.find(mappingID, on: req.db)
                    .unwrap(or: Abort(.notFound))
                    .flatMap { $0.$chatBoxes.attach(chatBox, on: req.db) }
            }.flatten(on: req.eventLoop).transform(to: .created)
        }
    }
    
    /// Bad code
//    func addchatBoxesHandlerOld(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
//        struct ResolveCreateMappingChatBox: Codable {
//            let mappingIDs: [UUID]
//        }
//        let updateUserData = try req.content.decode(ResolveCreateMappingChatBox.self)
//        let chatBox = ChatBox(name: "Friend")
//        let _ = chatBox.create(on: req.db)
//        return updateUserData.mappingIDs.map { mappingID in
//            print("handler 😀😀😀: \(#function), line: \(#line), \(mappingID)")
//            let mappingQuery = Mapping.find(mappingID, on: req.db).unwrap(or: Abort(.notFound))
//            let chatBoxQuery = ChatBox.find(chatBox.id, on: req.db).unwrap(or: Abort(.notFound))
//            return mappingQuery.and(chatBoxQuery).flatMap { mapping, chatBox in
//                mapping.$chatBoxes.attach(chatBox, on: req.db)
//            }
//        }.flatten(on: req.eventLoop).transform(to: .created)
//    }
    /// Optimal code syntax write by vzsg convert to async version
//        func addchatBoxesHandler(_ req: Request) async throws -> HTTPStatus {
//            struct ResolveCreateMappingChatBox: Codable {
//                let mappingIDs: [UUID]
//            }
//
//            let updateUserData = try req.content.decode(ResolveCreateMappingChatBox.self)
//            let chatBox = ChatBox(name: "Friend")
//            try await chatBox.save(on: req.db)
//
//                updateUserData.mappingIDs.map { mappingID in
//                    guard let mapping = try Mapping.find(mappingID, on: req.db) else {
//                        throw Abort(.notFound)
//                    }
//                    mapping.$chatBoxes.attach(chatBox, on: req.db)
//                }
//            return .created
//        }
    /// Optimal code syntax write by vzsg
    func addchatBoxesHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        struct ResolveCreateMappingChatBox: Codable {
            let mappingIDs: [UUID]
        }

        let resolvedModel = try req.content.decode(ResolveCreateMappingChatBox.self)
        let chatBox = ChatBox(name: "Friend")

        return chatBox.save(on: req.db).flatMap {
            resolvedModel.mappingIDs.map { mappingID in
                Mapping.find(mappingID, on: req.db)
                    .unwrap(or: Abort(.notFound))
                    .flatMap { $0.$chatBoxes.attach(chatBox, on: req.db) }
            }.flatten(on: req.eventLoop).transform(to: .created)
        }
    }
    
    func getchatBoxesHandler(_ req: Request) async throws -> [ChatBox] {
        print("handler 😀😀😀: \(#function), line: \(#line)")
        guard let mapping = try await Mapping.find(req.parameters.get("mappingID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return try await mapping.$chatBoxes.query(on: req.db).all()
    }
    
    /// Converting to async
//    func removechatBoxesHandler(_ req: Request) async throws -> HTTPStatus {
//        let mappingQuery = Mapping.find(req.parameters.get("mappingID"), on: req.db).unwrap(or: Abort(.notFound))
//        let chatBoxQuery = ChatBox.find(req.parameters.get("chatBoxID"), on: req.db).unwrap(or: Abort(.notFound))
//        let a = mappingQuery.and(chatBoxQuery)
//        a[0].$chatBoxes.detach(a[1], on: req.db)
//        return .noContent
//    }
//    func removechatBoxesHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
//        let mappingQuery = Mapping.find(req.parameters.get("mappingID"), on: req.db).unwrap(or: Abort(.notFound))
//        let chatBoxQuery = ChatBox.find(req.parameters.get("chatBoxID"), on: req.db).unwrap(or: Abort(.notFound))
//        return mappingQuery.and(chatBoxQuery).flatMap { mapping, chatBox in
//            mapping.$chatBoxes.detach(chatBox, on: req.db).transform(to: .noContent)
//        }
//    }
    func removechatBoxesHandler(_ req: Request) async throws -> HTTPStatus {
        guard let mappingQuery = try await Mapping.find(req.parameters.get("mappingID"), on: req.db) else {
            throw Abort(.notFound)
        }
        guard let chatBoxQuery = try await ChatBox.find(req.parameters.get("chatBoxID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await mappingQuery.$chatBoxes.detach(chatBoxQuery, on: req.db)
        return .noContent
    }
}

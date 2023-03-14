//
//  ChatBoxesController.swift
//  
//
//  Created by Dat Vu on 28/11/2022.
//

import Vapor

struct ChatBoxesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let chatBoxesRoute = routes.grouped("api", "chatBoxes")
        
        /// Auth
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = chatBoxesRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.post(":chatboxId", "members", use: addMembersIntoChatBoxesHandler)
        tokenAuthGroup.get(use: getAllHandler)
        tokenAuthGroup.get(":chatboxId", use: getHandler)
        tokenAuthGroup.get(":chatboxId", "mappings", use: chatboxMembersHandler)
        tokenAuthGroup.get(":chatboxId", "messages", use: getMessagesHandler)
        tokenAuthGroup.delete(":chatboxId", use: deleteChatBoxHandler)
        tokenAuthGroup.delete(":chatboxId", "members", ":userId", use: deleteMemberFromChatBoxHandler)
    }
    
    
    // MARK: - Create
    func createHandler(_ req: Request) async throws -> Chatbox {
        let chatBox = try req.content.decode(Chatbox.self)
        try await chatBox.save(on: req.db)
        return chatBox
    }
    func addMembersIntoChatBoxesHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        struct ResolveAddingMembersIntoChatBox: Codable {
            let mappingIds: [UUID]
        }
        guard let chatBoxId = req.parameters.get("chatboxId") else {
            throw Abort(.notFound)
        }
        let resolvedModel = try req.content.decode(ResolveAddingMembersIntoChatBox.self)
        return Chatbox.find(UUID(uuidString: chatBoxId), on: req.db).unwrap(or: Abort(.notFound)).flatMap { chatBox in
            resolvedModel.mappingIds.map { mappingId in
                let package = WebSocketPackage(type: .chatbox, message: WebSocketPackageMessage(id: nil, createdAt: nil, sender: nil, chatboxId: chatBox.id, mediaType: nil, content: nil))
                webSocketManager.send(to: resolvedModel.mappingIds, package: package)
                return User.find(mappingId, on: req.db)
                    .unwrap(or: Abort(.notFound))
                    .flatMap { $0.$chatboxes.attach(chatBox, on: req.db) }
            }.flatten(on: req.eventLoop).transform(to: .created)
        }
    }
    
    
    // MARK: - Get
    func getAllHandler(_ req: Request) async throws -> [Chatbox] {
        try await Chatbox.query(on: req.db).all()
    }
    func getHandler(_ req: Request) async throws -> Chatbox {
        guard let chatBox = try await Chatbox.find(req.parameters.get("chatboxId"), on: req.db) else {
            throw Abort(.notFound)
        }
        return chatBox
    }
    
    
    /// Rewrite
    func chatboxMembersHandler(_ req: Request) async throws -> [User] {
        guard let chatBox = try await Chatbox.find(req.parameters.get("chatboxId"), on: req.db) else {
            throw Abort(.notFound)
        }
        return try await chatBox.$users.get(on: req.db)
    }
    func getMessagesHandler(_ req: Request) async throws -> [Message] {
        guard let chatBox = try await Chatbox.find(req.parameters.get("chatboxId"), on: req.db) else {
            return []
        }
        return try await chatBox.$messages.get(on: req.db)
    }
    
    
    // MARK: - Delete
    func deleteChatBoxHandler(_ req: Request) async throws -> HTTPStatus {
        guard let chatBox = try await Chatbox.find(req.parameters.get("chatboxId"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await chatBox.delete(on: req.db)
        return .noContent
    }
    func deleteMemberFromChatBoxHandler(_ req: Request) async throws -> HTTPStatus {
        guard let chatboxQuery = try await Chatbox.find(req.parameters.get("chatboxId"), on: req.db) else {
            throw Abort(.notFound)
        }
        guard let userQuery = try await User.find(req.parameters.get("userId"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await userQuery.$chatboxes.detach(chatboxQuery, on: req.db)


//        let deletedUser = try await User.query(on: req.db).filter(\.$id == mappingQuery.$user.id).all()
//        let deletedUser = try await User.query(on: req.db).filter(\.$id == mappingQuery.$user.id).all()
//        let message = Message(sender: user.mappingId!, mediaType: MediaType.notify.rawValue, content: "\(user.name) đã xoá @\(deletedUser.username) khỏi nhóm!", chatboxId: chatBoxQuery.id)
//        try await message.save(on: req.db)
//
//        for mappingId in resolvedModel.mappingIds {
//            guard let mapping = try await Mapping.find(mappingId, on: req.db) else {
//                throw Abort(.notFound)
//            }
//            try await mapping.$chatBoxes.attach(chatBox, on: req.db)
//        }
//        let package = WebSocketPackage(type: .chatbox, message: WebSocketPackageMessage(id: nil, createdAt: message.createdAt, sender: user.mappingId, chatboxId: chatBox.id, mediaType: .text, content: message.content))


        let package = WebSocketPackage(type: .chatbox, message: WebSocketPackageMessage(id: nil, createdAt: nil, sender: nil, chatboxId: chatboxQuery.id, mediaType: nil, content: nil))
        webSocketManager.send(to: [userQuery.id], package: package)
        return .noContent
    }
}


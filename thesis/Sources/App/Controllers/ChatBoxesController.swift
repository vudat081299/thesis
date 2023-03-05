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
        
        chatBoxesRoute.get(use: getAllHandler)
        chatBoxesRoute.get(":chatBoxId", use: getHandler)
        chatBoxesRoute.get(":chatBoxId", "mappings", use: getMappingsHandler)
        chatBoxesRoute.get(":chatBoxId", "messages", use: getMessagesHandler)
        
        
        /// Auth
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = chatBoxesRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.post(":chatBoxId", "members", use: addMembersIntoChatBoxesHandler)
        tokenAuthGroup.delete(":chatBoxId", use: deleteChatBoxHandler)
        tokenAuthGroup.delete(":chatBoxId", "members", ":mappingId", use: deleteMemberFromChatBoxHandler)
    }
    
    
    // MARK: - Create
    func createHandler(_ req: Request) async throws -> ChatBox {
        let chatBox = try req.content.decode(ChatBox.self)
        try await chatBox.save(on: req.db)
        return chatBox
    }
    func addMembersIntoChatBoxesHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        struct ResolveAddingMembersIntoChatBox: Codable {
            let mappingIds: [UUID]
        }
        guard let chatBoxId = req.parameters.get("chatBoxId") else {
            throw Abort(.notFound)
        }
        let resolvedModel = try req.content.decode(ResolveAddingMembersIntoChatBox.self)
        return ChatBox.find(UUID(uuidString: chatBoxId), on: req.db).unwrap(or: Abort(.notFound)).flatMap { chatBox in
            resolvedModel.mappingIds.map { mappingId in
                let package = WebSocketPackage(type: .chatBox, message: WebSocketPackageMessage(id: nil, createdAt: nil, sender: nil, chatBoxId: chatBox.id, mediaType: nil, content: nil))
                webSocketManager.send(to: resolvedModel.mappingIds, package: package)
                return Mapping.find(mappingId, on: req.db)
                    .unwrap(or: Abort(.notFound))
                    .flatMap { $0.$chatBoxes.attach(chatBox, on: req.db) }
            }.flatten(on: req.eventLoop).transform(to: .created)
        }
    }
    
    
    // MARK: - Get
    func getAllHandler(_ req: Request) async throws -> [ChatBox] {
        try await ChatBox.query(on: req.db).all()
    }
    func getHandler(_ req: Request) async throws -> ChatBox {
        guard let chatBox = try await ChatBox.find(req.parameters.get("chatBoxId"), on: req.db) else {
            throw Abort(.notFound)
        }
        return chatBox
    }
    func getMappingsHandler(_ req: Request) async throws -> [Mapping] {
        guard let chatBox = try await ChatBox.find(req.parameters.get("chatBoxId"), on: req.db) else {
            throw Abort(.notFound)
        }
        return try await chatBox.$mappings.get(on: req.db)
    }
    func getMessagesHandler(_ req: Request) async throws -> [Message] {
        guard let chatBox = try await ChatBox.find(req.parameters.get("chatBoxId"), on: req.db) else {
            return []
        }
        return try await chatBox.$messages.get(on: req.db)
    }
    
    
    // MARK: - Delete
    func deleteChatBoxHandler(_ req: Request) async throws -> HTTPStatus {
        guard let chatBox = try await ChatBox.find(req.parameters.get("chatBoxId"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await chatBox.delete(on: req.db)
        return .noContent
    }
    func deleteMemberFromChatBoxHandler(_ req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        guard let chatBoxQuery = try await ChatBox.find(req.parameters.get("chatBoxId"), on: req.db) else {
            throw Abort(.notFound)
        }
        guard let mappingQuery = try await Mapping.find(req.parameters.get("mappingId"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await mappingQuery.$chatBoxes.detach(chatBoxQuery, on: req.db)
        
        
//        let deletedUser = try await User.query(on: req.db).filter(\.$id == mappingQuery.$user.id).all()
//        let deletedUser = try await User.query(on: req.db).filter(\.$id == mappingQuery.$user.id).all()
//        let message = Message(sender: user.mappingId!, mediaType: MediaType.notify.rawValue, content: "\(user.name) đã xoá @\(deletedUser.username) khỏi nhóm!", chatBoxId: chatBoxQuery.id)
//        try await message.save(on: req.db)
//
//        for mappingId in resolvedModel.mappingIds {
//            guard let mapping = try await Mapping.find(mappingId, on: req.db) else {
//                throw Abort(.notFound)
//            }
//            try await mapping.$chatBoxes.attach(chatBox, on: req.db)
//        }
//        let package = WebSocketPackage(type: .chatBox, message: WebSocketPackageMessage(id: nil, createdAt: message.createdAt, sender: user.mappingId, chatBoxId: chatBox.id, mediaType: .text, content: message.content))
        
        
        let package = WebSocketPackage(type: .chatBox, message: WebSocketPackageMessage(id: nil, createdAt: nil, sender: nil, chatBoxId: chatBoxQuery.id, mediaType: nil, content: nil))
        webSocketManager.send(to: [mappingQuery.id], package: package)
        return .noContent
    }
}

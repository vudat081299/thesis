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
        tokenAuthGroup.delete(":chatBoxId", use: deleteChatBoxHandler)
    }
    
    
    // MARK: - Create
    func createHandler(_ req: Request) async throws -> ChatBox {
        let chatBox = try req.content.decode(ChatBox.self)
        try await chatBox.save(on: req.db)
        return chatBox
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
}

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
        chatBoxesRoute.get(":chatBoxID", use: getHandler)
        chatBoxesRoute.get(":chatBoxID", "mappings", use: getMappingsHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = chatBoxesRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(use: createHandler)
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<ChatBox> {
        let chatBox = try req.content.decode(ChatBox.self)
        return chatBox.save(on: req.db).map { chatBox }
    }
    
    func getAllHandler(_ req: Request) -> EventLoopFuture<[ChatBox]> {
        ChatBox.query(on: req.db).all()
    }
    
    func getHandler(_ req: Request) -> EventLoopFuture<ChatBox> {
        ChatBox.find(req.parameters.get("chatBoxID"), on: req.db).unwrap(or: Abort(.notFound))
    }
    
    func getMappingsHandler(_ req: Request) -> EventLoopFuture<[Mapping]> {
        ChatBox.find(req.parameters.get("chatBoxID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { chatBox in
                chatBox.$mappings.get(on: req.db)
            }
    }
    
    func getMessagesHandler(_ req: Request) -> EventLoopFuture<[Message]> {
        ChatBox.find(req.parameters.get("chatBoxID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { chatBox in
            chatBox.$messages.get(on: req.db)
        }
    }
}

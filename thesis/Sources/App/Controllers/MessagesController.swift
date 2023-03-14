//
//  MessagesController.swift
//  
//
//  Created by Dat Vu on 28/11/2022.
//

import Vapor
import Fluent
import MongoKitten

struct MessagesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let messagesRoutes = routes.grouped("api", "messages")
        
        /// WebSocket
        messagesRoutes.webSocket("listen", ":userId", onUpgrade: webSocketHandler)
        
        /// Auth
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = messagesRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.get(use: index)
        tokenAuthGroup.get(":chatBoxId", "time", use: getLastestUpdateTime)
        tokenAuthGroup.get("messages", ":chatBoxId", ":time", use: getMessagesFromTime)
        tokenAuthGroup.delete("remove", "all", use: deleteAllHandler)
    }
    
    
    // MARK: - Create
    func createHandler(_ req: Request) async throws -> Message {
//        let user = try req.auth.require(User.self)
        guard let message = try Message(req.content.decode(WebSocketPackage.self)) else {
            throw Abort(.notAcceptable)
        }
        try await message.save(on: req.db)
        guard let chatbox = try await Chatbox.find(message.chatbox.id, on: req.db) else {
            throw Abort(.notFound)
        }
        let mappings = try await chatbox.$users.get(on: req.db)
        webSocketManager.send(to: mappings, message: message)
        return message
    }
    
    
    // MARK: - Get
    func index(req: Request) async throws -> [Message] {
        try await Message.query(on: req.db).all()
    }
    func getLastestUpdateTime(req: Request) async throws -> String {
        guard let chatBoxId = req.parameters.get("chatBoxId"),
              let chatBoxUUID = UUID(chatBoxId) else {
            throw Abort(.notFound)
        }
        guard let lastestUpdateTime = try await Message
            .query(on: req.db)
            .filter(\.$chatbox.$id == chatBoxUUID)
            .max(\.$createdAt) else {
            throw Abort(.notFound)
        }
        return lastestUpdateTime
    }
    func getMessagesFromTime(req: Request) async throws -> [Message] {
        guard let chatBoxId = req.parameters.get("chatBoxId"),
              let chatBoxUUID = UUID(chatBoxId) else {
            throw Abort(.notFound)
        }
        guard let timestamp = req.parameters.get("time") else {
            throw Abort(.notFound)
        }
        return try await Message.query(on: req.db)
            .filter(\.$chatbox.$id == chatBoxUUID)
            .filter(\.$createdAt > timestamp)
            .all()
    }
    
    
    // MARK: - Delete
    func deleteAllHandler(req: Request) async throws -> HTTPStatus {
        let messages = try await Message.query(on: req.db).all()
        for message in messages {
            try await message.delete(on: req.db)
        }
        return .noContent
    }
    
    
    // MARK: - WebSocket
    /*
     {
        "type": 0,
        "content": {
          "sender":"9B655BEA-9D66-40FD-907D-32F94E30FE6E",
          "chatBoxId":"CB2638C3-A01C-4810-9C04-8CDCD4449069",
          "mediaType": 0,
          "message":"test"
        }
     }
     */
    func webSocketHandler(_ req: Request, _ ws: WebSocket) {
        guard let userId = req.parameters.get("userId", as: UUID.self) else { return }
        webSocketManager.add(ws: ws, to: userId.uuidString)
        ws.onClose.whenComplete { result in
            // Succeeded or failed to close.
            switch result {
            case .success:
                webSocketManager.removeSession(of: userId.uuidString)
                print("close ws successful!")
                break
                
            case .failure:
                print("close ws unsuccessful!")
                break
            }
        }
        ws.onText() { onTextHandler($0, $1) }
        
        func onTextHandler(_ ws: WebSocket, _ text: String) {
            guard let data = text.data(using: .utf8),
                  let webSocketPackage = try? JSONDecoder().decode(WebSocketPackage.self, from: data) else {
                return
            }
            switch webSocketPackage.type {
            case .message:
                guard let message = Message(webSocketPackage) else {
                    return
                }
                let _ = message.save(on: req.db).flatMap {
                    Chatbox.find(message.$chatbox.id, on: req.db)
                        .unwrap(or: Abort(.notFound))
                        .map { chatBox in
                            chatBox.$users.get(on: req.db).map { mappings in
                                webSocketManager.send(to: mappings, message: message)
                            }
                        }
                }
                break
            case .call:
                guard let message = Message(webSocketPackage) else {
                    return
                }
                let _ = Chatbox.find(webSocketPackage.message.chatboxId, on: req.db)
                    .unwrap(or: Abort(.notFound))
                    .map { chatBox in
                        chatBox.$users.get(on: req.db).map { users in
                            webSocketManager.send(to: users.map { $0.id }, package: webSocketPackage)
                        }
                    }
            default:
                break
            }
        }
    }
}

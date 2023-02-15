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
        
        messagesRoutes.get(use: index)
        messagesRoutes.delete("remove", "all", use: deleteAllHandler)
        messagesRoutes.get(":chatBoxId", "time", use: getLastestUpdateTime)
        messagesRoutes.get("messages", ":chatBoxId", ":time", use: getMessagesFromTime)
        
        /// WebSocket
        messagesRoutes.webSocket("listen", ":mappingId", onUpgrade: webSocketHandler)
        
        /// Auth
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = messagesRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.post(use: createHandler)
    }
    
    
    // MARK: - Create
    func createHandler(_ req: Request) async throws -> Message {
//        let user = try req.auth.require(User.self)
        guard let message = try Message(req.content.decode(WebSocketPackage.self)) else {
            throw Abort(.notAcceptable)
        }
        try await message.save(on: req.db)
        guard let chatBox = try await ChatBox.find(message.chatBox.id, on: req.db) else {
            throw Abort(.notFound)
        }
        let mappings = try await chatBox.$mappings.get(on: req.db)
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
            .filter(\.$chatBox.$id == chatBoxUUID)
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
            .filter(\.$chatBox.$id == chatBoxUUID)
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
        guard let mappingId = req.parameters.get("mappingId", as: UUID.self) else { return }
        webSocketManager.add(ws: ws, to: mappingId.uuidString)
        ws.onClose.whenComplete { result in
            // Succeeded or failed to close.
            switch result {
            case .success:
                webSocketManager.removeSession(of: mappingId.uuidString)
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
                    ChatBox.find(message.$chatBox.id, on: req.db)
                        .unwrap(or: Abort(.notFound))
                        .map { chatBox in
                            chatBox.$mappings.get(on: req.db).map { mappings in
                                webSocketManager.send(to: mappings, message: message)
                            }
                        }
                }
                break
//            case .chatBox:
//                break
//            case .user:
//                break
            default:
                break
            }
        }
    }
    
    
    
//    func webSocketHandler(_ req: Request, _ ws: WebSocket) async {
//        ws.onText() { ws, text async in
//            guard let data = text.data(using: .utf8),
//                  let resolvedMessage = try? JSONDecoder().decode(ResolveMessage.self, from: data) else {
//                return
//            }
//            let message = Message(resolvedMessage)
//            try? await message.save(on: req.db)
//            if let chatBox = try? await ChatBox.find(resolvedMessage.chatBoxID, on: req.db),
//               let mappings = try? await chatBox.$mappings.get(on: req.db) {
//                webSocketManager.mess(to: mappings, message: resolvedMessage)
//            }
//
//        }
////        ws.onText() { onTextHandler($0, $1) }
////
////        func onTextHandler(_ ws: WebSocket, _ text: String) async {
////            guard let data = text.data(using: .utf8),
////                  let resolvedMessage = try? JSONDecoder().decode(ResolveMessage.self, from: data) else {
////                      return
////                  }
////            let message = Message(resolvedMessage)
////            await message.save(on: req.db)
////            let _ = ChatBox.find(resolvedMessage.chatBoxID, on: req.db)
////                .unwrap(or: Abort(.notFound))
////                .map { chatBox in
////                    chatBox.$mappings.get(on: req.db).map { mappings in
////                        webSocketManager.mess(to: mappings, message: resolvedMessage)
////                    }
////                }
////        }
//    }
    
    
//    func addchatBoxesHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
//        struct ResolveCreateMappingChatBox: Codable {
//            let mappingIds: [UUID]
//        }
//
//        let updateUserData = try req.content.decode(ResolveCreateMappingChatBox.self)
//        let chatBox = ChatBox(name: "Friend")
//
//        return chatBox.create(on: req.db).flatMap {
//            updateUserData.mappingIds.map { mappingId in
//                Mapping.find(mappingId, on: req.db)
//                    .unwrap(or: Abort(.notFound))
//                    .flatMap { $0.$chatBoxes.attach(chatBox, on: req.db) }
//            }.flatten(on: req.eventLoop).transform(to: .created)
//        }
//    }
    
    
    
    // MARK: - WebSocket
//    app.webSocket("echo") { req, ws in
//        // Connected WebSocket.
//        print(ws)
//        
//        // Echoes received messages.
//        ws.onText { ws, text in
//        }
//    }
//    
//    // Create first web socket conection.
//    app.webSocket("connect", ":userID") { req, ws in
//        guard let userID = req.parameters.get("userID") else {
//            return
//        }
//        webSocketPerUserManager.add(ws: ws, to: userID)
//    }
}

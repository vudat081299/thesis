//
//  MessagesController.swift
//  
//
//  Created by Dat Vu on 28/11/2022.
//

import Vapor
import Fluent

struct MessagesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let messagesRoutes = routes.grouped("api", "messages")
        messagesRoutes.get(use: index)
        messagesRoutes.webSocket("listen", ":userID", onUpgrade: webSocketHandler)
        messagesRoutes.delete("remove", "all", use: deleteAllHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = messagesRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(use: createHandler)
        
    }
    
    func createHandler(_ req: Request) async throws -> Message {
        let user = try req.auth.require(User.self)
        let message = try Message(req.content.decode(ResolveMessage.self))
        try await message.save(on: req.db)
        guard let chatBox = try await ChatBox.find(message.chatBox.id, on: req.db) else {
            throw Abort(.notFound)
        }
        let mappings = try await chatBox.$mappings.get(on: req.db)
        webSocketManager.mess(to: mappings, message: message)
        return message
    }
    
    func index(req: Request) async throws -> [Message] {
        try await Message.query(on: req.db).all()
    }
    
    func deleteAllHandler(req: Request) async throws -> HTTPStatus {
        let messages = try await Message.query(on: req.db).all()
        for message in messages {
            try await message.delete(on: req.db)
        }
        return .noContent
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
    
    /*
     {
     "sender":"175EE261-2E4C-437A-9782-50B2048785B5",
     "chatBoxID":"D87FD086-3BE3-4895-B604-890474AFF4C3",
     "message":"test1"
     }
     */
    func webSocketHandler(_ req: Request, _ ws: WebSocket) {
        guard let userID = req.parameters.get("userID", as: UUID.self) else { return }
        webSocketManager.add(ws: ws, to: userID.uuidString)
        ws.onClose.whenComplete { result in
            // Succeeded or failed to close.
            switch result {
            case .success:
                webSocketManager.removeSession(of: userID.uuidString)
                print("close ws successful!")
                break
                
            case .failure:
                print("close ws unsuccessful!")
                break
            }
        }
        ws.onText() { onTextHandler($0, $1) }
        
        func onTextHandler(_ ws: WebSocket, _ text: String) {
            print(text)
            guard let data = text.data(using: .utf8),
                  let resolvedMessage = try? JSONDecoder().decode(ResolveMessage.self, from: data) else {
                      return
                  }
            let message = Message(resolvedMessage)
            print(message)
            let _ = message.save(on: req.db).flatMap {
                ChatBox.find(message.$chatBox.id, on: req.db)
                        .unwrap(or: Abort(.notFound))
                        .map { chatBox in
                            chatBox.$mappings.get(on: req.db).map { mappings in
                                webSocketManager.mess(to: mappings, message: message)
                            }
                        }
            }
        }
    }
    
//    func addchatBoxesHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
//        struct ResolveCreateMappingChatBox: Codable {
//            let mappingIDs: [UUID]
//        }
//
//        let updateUserData = try req.content.decode(ResolveCreateMappingChatBox.self)
//        let chatBox = ChatBox(name: "Friend")
//
//        return chatBox.create(on: req.db).flatMap {
//            updateUserData.mappingIDs.map { mappingID in
//                Mapping.find(mappingID, on: req.db)
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

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
        messagesRoutes.webSocket(onUpgrade: createHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = messagesRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
    }
    
    func createHandler(_ req: Request, _ ws: WebSocket) {
//        let data = try req.content.decode(CreateMappingData.self)
        let user = try req.auth.require(User.self)
        let mapping = try Mapping(userID: user.requireID())
        return mapping.save(on: req.db).map { mapping }
    }
    
    
    
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

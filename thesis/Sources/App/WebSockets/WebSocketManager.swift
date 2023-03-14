//
//  WebSocketManager.swift
//  
//
//  Created by Vũ Quý Đạt  on 07/05/2021.
//

import Vapor

var webSocketManager = WebSocketManager()
final class WebSocketManager {
    var dictionary: [String: WebSocket] = [:]
    
    
    // MARK: - Session manager
    func add(ws: WebSocket, to userId: String) {
        dictionary[userId] = ws
        print("Add new WebSocket connection user ID: \(userId)!")
    }
    
    func removeSession(of userId: String) {
        if dictionary[userId] != nil {
            dictionary.removeValue(forKey: userId)
        }
    }
    
    
    // MARK: -
    func send(to user: [User], message: Message) {
        user.forEach { user in
            if let userId = user.id,
               let ws = dictionary[userId.uuidString] {
                ws.send(message.convertToWebSocketPackage())
                print(userId)
            }
        }
    }
    func send(to userIds: [UUID?], package: WebSocketPackage) {
        userIds.forEach { userId in
            if let userId = userId, let ws = dictionary[userId.uuidString] {
                ws.send(package)
            }
        }
    }
}


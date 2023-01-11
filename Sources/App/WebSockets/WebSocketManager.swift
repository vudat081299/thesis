//
//  WebSocketManager.swift
//  
//
//  Created by Vũ Quý Đạt  on 07/05/2021.
//

import Vapor

let webSocketManager = WebSocketManager()
final class WebSocketManager {
    var dictionary: [String: WebSocket] = [:]
    
    // MARK: - Session manager
    func add(ws: WebSocket, to userID: String) {
        dictionary[userID] = ws
        print("Add new WebSocket connection user ID: \(userID)!")
    }
    
    func removeSession(of userID: String) {
        if dictionary[userID] != nil {
            dictionary.removeValue(forKey: userID)
        }
    }
    
    
    
    // MARK: -
    func mess(to userMapping: [Mapping], message: Message) {
        print(dictionary)
        userMapping.forEach { mapping in
            let userID = mapping.$user.id
            if let ws = dictionary[userID.uuidString] {
                ws.send(message)
            }
        }
    }
}


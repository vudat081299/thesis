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
    func add(ws: WebSocket, to mappingId: String) {
        dictionary[mappingId] = ws
        print("Add new WebSocket connection user ID: \(mappingId)!")
    }
    
    func removeSession(of userID: String) {
        if dictionary[userID] != nil {
            dictionary.removeValue(forKey: userID)
        }
    }
    
    
    // MARK: -
    func send(to userMapping: [Mapping], message: Message) {
        userMapping.forEach { mapping in
            if let mappingId = mapping.id,
               let ws = dictionary[mappingId.uuidString] {
                ws.send(message.convertToWebSocketPackage())
            }
        }
    }
}


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
    
    func add(ws: WebSocket, to userID: String) {
        if dictionary[userID] == nil {
            dictionary[userID] = ws
        }
        print("Add new WebSocket connection user ID: \(userID)!")
    }
    
    func removeSession(of userID: String) {
        if dictionary[userID] != nil {
            dictionary.removeValue(forKey: userID)
        }
    }
}


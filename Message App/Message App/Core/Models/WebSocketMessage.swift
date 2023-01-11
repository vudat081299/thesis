//
//  WebSocketMessage.swift
//  
//
//  Created by Dat Vu on 04/12/2022.
//

import Foundation

struct WebSocketMessage: Codable {
    let id: UUID
    let chatBox: ResolveUUID
    let message: String
    let sender: UUID
    let createdAt: Date
}

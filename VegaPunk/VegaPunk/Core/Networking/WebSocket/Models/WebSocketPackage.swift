//
//  WebSocketPackage.swift
//
//
//  Created by Dat Vu on 29/11/2022.
//

import Foundation

enum WebSocketPackageType: Int, Codable {
    case message, chatBox, user
}

struct WebSocketPackageMessage: Codable {
    // message
    let id: UUID?
    let createdAt: String?
    let sender: UUID? // mappingId
    let chatBoxId: UUID?
    let mediaType: MediaType?
    let content: String?
    
    init(id: UUID? = nil, createdAt: String? = nil, sender: UUID? = nil, chatBoxId: UUID? = nil, mediaType: MediaType? = nil, content: String? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.sender = sender
        self.chatBoxId = chatBoxId
        self.mediaType = mediaType
        self.content = content
    }
}

struct WebSocketPackage: Codable {
    let type: WebSocketPackageType
    let message: WebSocketPackageMessage
    
    func convertToMessage() -> Message {
        return Message(id: message.id!, createdAt: message.createdAt!, sender: message.sender!, chatBoxId: message.chatBoxId!, mediaType: message.mediaType ?? .text , content: message.content!)
    }
}

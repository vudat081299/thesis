//
//  WebSocketPackage.swift
//
//
//  Created by Dat Vu on 29/11/2022.
//

import Foundation

enum WebSocketPackageType: Int, Codable {
    case message, chatbox, user, call
}

struct WebSocketPackageMessage: Codable {
    // message
    let id: UUID?
    let createdAt: String?
    let sender: UUID? // mappingId
    let chatboxId: UUID?
    let mediaType: MediaType?
    let content: String?
    
    init(id: UUID? = nil, createdAt: String? = nil, sender: UUID? = nil, chatboxId: UUID? = nil, mediaType: MediaType? = nil, content: String? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.sender = sender
        self.chatboxId = chatboxId
        self.mediaType = mediaType
        self.content = content
    }
}

struct WebSocketPackage: Codable {
    enum WebSocketError: Error {
       case cannotParsePackageToJsonString
    }
    
    let type: WebSocketPackageType
    let message: WebSocketPackageMessage
    
    func convertToMessage() -> ChatboxMessage {
        return ChatboxMessage(id: message.id!, createdAt: message.createdAt!, sender: message.sender!, chatboxId: message.chatboxId!, mediaType: message.mediaType ?? .text , content: message.content!)
    }
    func json() throws -> String {
        guard let jsonString = try String(data: JSONEncoder().encode(self), encoding: .utf8) else { throw WebSocketError.cannotParsePackageToJsonString }
        return jsonString
    }
}

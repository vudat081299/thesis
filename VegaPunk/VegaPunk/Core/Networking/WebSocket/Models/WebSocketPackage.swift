//
//  WebSocketPackage.swift
//
//
//  Created by Dat Vu on 29/11/2022.
//

import Foundation
import CryptoSwift

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
    enum WebSocketError: Error {
       case cannotParsePackageToJsonString
    }
    
    let type: WebSocketPackageType
    let message: WebSocketPackageMessage
    
    func convertToMessage() -> ChatBoxMessage? {
        do {
            let aes = try AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7)
            let decrypted = try aes.decrypt(message.content!.transformToArrayUInt8())
            if let plainText = String(bytes: decrypted, encoding: .utf8) {
                return ChatBoxMessage(id: message.id!, createdAt: message.createdAt!, sender: message.sender!, chatBoxId: message.chatBoxId!, mediaType: message.mediaType ?? .text , content: plainText)
            } else {
                return nil
            }
        } catch {
            return nil
        }
        
    }
    func json() throws -> String {
        guard let jsonString = try String(data: JSONEncoder().encode(self), encoding: .utf8) else { throw WebSocketError.cannotParsePackageToJsonString }
        return jsonString
    }
}

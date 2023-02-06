//
//  Message.swift
//  
//
//  Created by Dat Vu on 28/11/2022.
//

import Vapor
import Fluent

enum MediaType: String, Codable {
    case text, file
}

final class Message: Model {
    static let schema = "messages"
    
    @ID
    var id: UUID?
    
    @Field(key: "createdAt")
    var createdAt: String?
    
    @Field(key: "sender")
    /// mappingId of user
    var sender: UUID
    
    @Field(key: "mediaType")
    var mediaType: String
    
    @Field(key: "content")
    var content: String
    
    @Parent(key: "chatBoxId")
    var chatBox: ChatBox
    
    //
    init() {}
    
    init(id: UUID? = nil, sender: UUID, mediaType: String?, content: String, chatBoxID: ChatBox.IDValue) {
        self.id = id
        self.createdAt = Date().milliStampString
        self.sender = sender
        self.mediaType = mediaType ?? MediaType.text.rawValue
        self.content = content
        self.$chatBox.id = chatBoxID
    }
    
    init?(id: UUID? = nil, _ package: WebSocketPackage) {
        self.id = id
        self.createdAt = Date().milliStampString
        guard let packageMessageSender = package.message.sender,
              let packageMessageMediaType = package.message.mediaType,
              let packageMessageContent = package.message.content,
              let packageMessageChatBoxId = package.message.chatBoxId
        else {
            return nil
        }
        self.sender = packageMessageSender
        self.mediaType = packageMessageMediaType
        self.content = packageMessageContent
        self.$chatBox.id = packageMessageChatBoxId
    }
}

extension Message: Content {}
extension Message {
    func convertToWebSocketPackage() -> WebSocketPackage {
        return WebSocketPackage(type: .message, message: WebSocketPackageMessage(createdAt: createdAt, sender: sender, chatBoxId: self.$chatBox.id, mediaType: mediaType, content: content))
    }
}



// MARK: - WebSocket model

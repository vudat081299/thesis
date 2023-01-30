//
//  Message.swift
//  
//
//  Created by Dat Vu on 28/11/2022.
//

import Vapor
import Fluent

final class Message: Model {
    static let schema = "messages"
    
    @ID
    var id: UUID?
    
    @Field(key: "sender")
    var sender: UUID
    
    @Field(key: "message")
    var message: String
    
    @Field(key: "createdAt")
    var createdAt: String?
    
    @Parent(key: "chatBoxId")
    var chatBox: ChatBox
    
    //
    
    init() {}
    
    init(id: UUID? = nil, sender: UUID, message: String, chatBoxID: ChatBox.IDValue) {
        self.id = id
        self.sender = sender
        self.message = message
        
        self.$chatBox.id = chatBoxID
    }
    
    init(id: UUID? = nil, _ resolvedMessage: ResolveMessage) {
        self.id = id
        self.sender = resolvedMessage.sender
        self.message = resolvedMessage.message
        self.createdAt = resolvedMessage.createdAt
        
        self.$chatBox.id = resolvedMessage.chatBoxID
    }
}

extension Message: Content {}



// MARK: - WebSocket model
struct WSResolvedData: Decodable {
    let type: WSResolvedMajorDataType
}

enum WSResolvedMajorDataType: Int, Codable {
    case notify, newMess, newBox, userTyping
}

struct WSEncodeMessage: Encodable {
    let type: WSResolvedMajorDataType
    let majorData: Message
}

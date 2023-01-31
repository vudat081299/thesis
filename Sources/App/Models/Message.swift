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
    
    @Field(key: "createdAt")
    var createdAt: String?
    
    @Field(key: "sender")
    /// mappingId of user
    var sender: UUID
    
    @Boolean(key: "isFile")
    var isFile: Bool
    
    @Field(key: "message")
    var message: String
    
    @Parent(key: "chatBoxId")
    var chatBox: ChatBox
    
    //
    init() {}
    
    init(id: UUID? = nil, sender: UUID, isFile: Bool?, message: String, chatBoxID: ChatBox.IDValue) {
        self.id = id
        self.createdAt = Date().milliStampString
        self.sender = sender
        self.isFile = isFile ?? false
        self.message = message
        self.$chatBox.id = chatBoxID
    }
    
    init(id: UUID? = nil, _ package: ResolveWebSocketPackage) {
        self.id = id
        self.createdAt = Date().milliStampString
        self.sender = package.content.sender
        self.isFile = package.content.isFile ?? false
        self.message = package.content.message
        self.$chatBox.id = package.content.chatBoxId
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

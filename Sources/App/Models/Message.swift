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
    
    @Field(key: "message")
    var message: String
    
    @Timestamp(key: "createAt", on: .create)
    var createAt: Date?
    
    @Parent(key: "chatBoxID")
    var chatBox: ChatBox
    
    //
    
    init() {}
    
    init(id: UUID? = nil, chatBoxID: ChatBox.IDValue) {
        self.id = id
        self.$chatBox.id = chatBoxID
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

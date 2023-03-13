//
//  MappingChatBoxPivot.swift
//  
//
//  Created by Dat Vu on 28/11/2022.
//

import Fluent
import Vapor

final class ChatboxMembers: Model, Content {
    static let schema = "chatbox-members"
    
    @ID
    var id: UUID?
    
    @Parent(key: "userId")
    var user: User
    
    @Parent(key: "chatboxId")
    var chatbox: Chatbox
    
    init() {}
    
    init(id: UUID? = nil, user: User, chatbox: Chatbox) throws {
        self.id = id
        self.$user.id = try user.requireID()
        self.$chatbox.id = try chatbox.requireID()
    }
}

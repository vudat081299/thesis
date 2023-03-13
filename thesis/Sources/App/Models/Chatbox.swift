//
//  ChatBox.swift
//  
//
//  Created by Dat Vu on 28/11/2022.
//

import Fluent
import Vapor

final class Chatbox: Model, Content {
    static let schema = "chatboxes"
    
    @ID
    var id: UUID?
    
    @Field(key: "name")
    var name: String?
    
    @OptionalField(key: "avatar")
    var avatar: String?
    
    @Children(for: \.$chatbox)
    var messages: [Message]
    
    @Siblings(through: ChatboxMembers.self, from: \.$chatbox, to: \.$user)
    var users: [User]
    
    init() {}
    
    init(id: UUID? = nil,
         name: String? = nil,
         avatar: String? = nil) {
        self.id = id
        self.name = name
        self.avatar = avatar
    }
}

extension Chatbox {
    static func addChatbox(_ name: String, to user: User, on req: Request) -> EventLoopFuture<Void> {
        Chatbox.query(on: req.db)
            .filter(\.$name == name)
            .first()
            .flatMap { foundChatBox in
                if let existingChatBox = foundChatBox {
                    return user.$chatboxes
                        .attach(existingChatBox, on: req.db)
                } else {
                    let chatBox = Chatbox(name: name)
                    return chatBox.save(on: req.db).flatMap {
                        user.$chatboxes
                            .attach(chatBox, on: req.db)
                    }
                }
            }
    }
}

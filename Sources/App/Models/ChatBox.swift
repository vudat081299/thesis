//
//  ChatBox.swift
//  
//
//  Created by Dat Vu on 28/11/2022.
//

import Fluent
import Vapor

final class ChatBox: Model, Content {
    static let schema = "chatBoxes"
    
    @ID
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Children(for: \.$chatBox)
    var messages: [Message]
    
    @Siblings(through: MappingChatBoxPivot.self, from: \.$chatBox, to: \.$mapping)
    var mappings: [Mapping]
    
    init() {}
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

extension ChatBox {
    static func addCategory(_ name: String, to mapping: Mapping, on req: Request) -> EventLoopFuture<Void> {
        ChatBox.query(on: req.db)
            .filter(\.$name == name)
            .first()
            .flatMap { foundChatBox in
                if let existingChatBox = foundChatBox {
                    return mapping.$chatBoxes
                        .attach(existingChatBox, on: req.db)
                } else {
                    let chatBox = ChatBox(name: name)
                    return chatBox.save(on: req.db).flatMap {
                        mapping.$chatBoxes
                            .attach(chatBox, on: req.db)
                    }
                }
            }
    }
}

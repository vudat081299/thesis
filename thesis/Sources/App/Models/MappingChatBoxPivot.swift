//
//  MappingChatBoxPivot.swift
//  
//
//  Created by Dat Vu on 28/11/2022.
//

import Fluent
import Vapor

final class MappingChatBoxPivot: Model, Content {
    static let schema = "mapping-chatbox-pivot"
    
    @ID
    var id: UUID?
    
    @Parent(key: "mappingId")
    var mapping: Mapping
    
    @Parent(key: "chatBoxId")
    var chatBox: ChatBox
    
    init() {}
    
    init(id: UUID? = nil, mapping: Mapping, chatBox: ChatBox) throws {
        self.id = id
        self.$mapping.id = try mapping.requireID()
        self.$chatBox.id = try chatBox.requireID()
    }
}

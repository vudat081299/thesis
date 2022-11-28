//
//  MappingChatBoxPivot.swift
//  
//
//  Created by Dat Vu on 28/11/2022.
//

import Fluent
import Foundation

final class MappingChatBoxPivot: Model {
    static let schema = "mapping-chatbox-pivot"
    
    @ID
    var id: UUID?
    
    @Parent(key: "mappingID")
    var mapping: Mapping
    
    @Parent(key: "chatBoxID")
    var chatBox: ChatBox
    
    init() {}
    
    init(id: UUID? = nil, mapping: Mapping, chatBox: ChatBox) throws {
        self.id = id
        self.$mapping.id = try mapping.requireID()
        self.$chatBox.id = try chatBox.requireID()
    }
}

//
//  Mapping.swift
//  
//
//  Created by Dat Vu on 28/11/2022.
//

import Vapor
import Fluent

//final class Mapping: Model {
//    static let schema = "mappings"
//    
//    @ID
//    var id: UUID?
//    
////    @Field(key: "short")
////    var short: String
////
////    @Field(key: "long")
////    var long: String
//    
//    @Parent(key: "userID")
//    var user: User
//    
//    @Siblings(through: ChatboxMembers.self, from: \.$user, to: \.$chatbox)
//    var chatBoxes: [Chatbox]
//    
//    init() {}
//    
//    init(id: UUID? = nil, userID: User.IDValue) {
//        self.id = id
//        
//        self.$user.id = userID
//    }
//}
//
//extension Mapping: Content {}

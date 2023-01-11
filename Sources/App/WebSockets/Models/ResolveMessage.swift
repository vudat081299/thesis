//
//  Message.swift
//  
//
//  Created by Dat Vu on 29/11/2022.
//

import Foundation

struct ResolveMessage: Codable {
    let id: UUID?
    let sender: UUID
    let createdAt: String
    let chatBoxID: UUID
    let message: String
    
//    enum CodingKeys: CodingKey {
//        case sender
//        case chatBoxID
//        case message
//    }
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.sender = try container.decode(UUID.self, forKey: .sender)
//        self.chatBoxID = try container.decode(UUID.self, forKey: .chatBoxID)
//        self.message = try container.decode(String.self, forKey: .message)
//    }
}

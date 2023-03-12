//
//  File.swift
//  
//
//  Created by Dat Vu on 04/12/2022.
//

import Foundation

struct ChatBox: Codable {
    let id: UUID
    let name: String?
    let avatar: String?
    var mappings: [ResolveMapping] = []
    var messages: [WebSocketMessage] = []
}

enum DefaultAvartar: Int, Codable {
    case nonee, engineer, pianist, male, female, other
}

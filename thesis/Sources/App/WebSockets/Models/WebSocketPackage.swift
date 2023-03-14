//
//  WebSocketPackage.swift
//  
//
//  Created by Dat Vu on 29/11/2022.
//

import Foundation

enum WebSocketPackageType: Int, Codable {
    case message, chatbox, user, call
}

struct WebSocketPackageMessage: Codable {
    // message
    let id: UUID?
    let createdAt: String?
    let sender: UUID?
    let chatboxId: UUID?
    let mediaType: MediaType?
    var content: String?
}

struct WebSocketPackage: Codable {
    let type: WebSocketPackageType
    var message: WebSocketPackageMessage
}

//
//  WebSocketPackage.swift
//  
//
//  Created by Dat Vu on 29/11/2022.
//

import Foundation

enum WebSocketPackageType: Int, Codable {
    case message, chatBox, user
}

struct WebSocketPackageMessage: Codable {
    // message
    let id: UUID?
    let createdAt: String?
    let sender: UUID?
    let chatBoxId: UUID?
    let mediaType: MediaType?
    let content: String?
}

struct WebSocketPackage: Codable {
    let type: WebSocketPackageType
    let message: WebSocketPackageMessage
}

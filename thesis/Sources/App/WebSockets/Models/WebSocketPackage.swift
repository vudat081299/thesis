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
    let createdAt: String?
    let sender: UUID? // mappingId
    let chatBoxId: UUID?
    let mediaType: String?
    let content: String?
}

struct WebSocketPackage: Codable {
    let type: WebSocketPackageType
    let message: WebSocketPackageMessage
}

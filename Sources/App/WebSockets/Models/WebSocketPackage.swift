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

struct WebSocketPackageContent: Codable {
    // message
    let sender: UUID // mappingId
    let chatBoxId: UUID
    let isFile: Bool?
    let message: String
}

struct ResolveWebSocketPackage: Codable {
    let type: WebSocketPackageType
    let content: WebSocketPackageContent
}

//
//  NSNotification.swift
//  VegaPunk
//
//  Created by Dat Vu on 12/02/2023.
//

import Foundation

extension NSNotification.Name {
    static var WebsocketReceivedMessagePackage: Notification.Name { return .init(rawValue: "WebsocketReceivedMessagePackage") }
    static var WebsocketReceivedChatBoxPackage: Notification.Name { return .init(rawValue: "WebsocketReceivedChatBoxPackage") }
    static var WebsocketReceivedUserPackage: Notification.Name { return .init(rawValue: "WebsocketReceivedUserPackage") }
    static var WebsocketReceivedCallPackage: Notification.Name { return .init(rawValue: "WebsocketReceivedCallPackage") }
    
    static var WebsocketSendPackage: Notification.Name { return .init(rawValue: "WebsocketSendPackage") }
    
}

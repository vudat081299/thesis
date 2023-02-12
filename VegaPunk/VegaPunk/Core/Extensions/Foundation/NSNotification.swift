//
//  NSNotification.swift
//  VegaPunk
//
//  Created by Dat Vu on 12/02/2023.
//

import Foundation

extension NSNotification.Name {
    static var WebsocketReceivedPackage: Notification.Name { return .init(rawValue: "WebsocketReceivedPackage") }
    static var WebsocketSendPackage: Notification.Name { return .init(rawValue: "WebsocketSendPackage") }
    
}

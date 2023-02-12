//
//  UserDefaults+Keys.swift
//  VegaPunk
//
//  Created by Dat Vu on 08/02/2023.
//

import Foundation

extension UserDefaults {
    enum Keys: String, CaseIterable {
        case authenticatedUser
        
        // For message feature
        case lastestSeenMessage
        case lastestMessage
        
        func genKey(_ suffix: String? = nil) -> String {
            guard let suffix = suffix else { return self.rawValue }
            return self.rawValue + "_" + suffix
        }
    }
    
    enum FilePaths: String, CaseIterable {
        case friends
        case mappings
        case chatBoxes
        case mappingChatBoxPivots
        case messages
        
//        func genKey(_ suffix: String? = nil) -> String {
//            guard let suffix = suffix else { return self.rawValue }
//            return self.rawValue + "_" + suffix
//        }
    }
}

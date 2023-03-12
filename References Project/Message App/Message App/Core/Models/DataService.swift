//
//  DataService.swift
//  
//
//  Created by Dat Vu on 04/12/2022.
//

import Foundation

/*
 Naming conventions:
 - In app model: normal name.
 - Decodable model: name prefix Resolve..
 - Encodable mode: name suffix ..Content
 */

final class DataService {
    static var friends: [User] {
        get {
            if let data = UserDefaults.standard.object(forKey: FRIENDS_KEY) as? Data {
                if let friends = try? JSONDecoder().decode([User].self, from: data) {
                    return friends
                }
            }
            return []
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: FRIENDS_KEY)
            }
        }
    }
    static var chatBoxes: [ChatBox] {
        get {
            if let savedChatBoxesData = UserDefaults.standard.object(forKey: CHATBOXES_KEY) as? Data {
                if let chatBoxes = try? JSONDecoder().decode([ChatBox].self, from: savedChatBoxesData) {
                    return chatBoxes
                    
                }
            }
            return []
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: CHATBOXES_KEY)
            }
        }
    }
    
    static var userIDMappingIdMap: [UUID: UUID] {
        get {
            if let savedMap = UserDefaults.standard.object(forKey: USER_ID_MAPPING_ID_KEY) as? Data {
                if let map = try? JSONDecoder().decode([UUID: UUID].self, from: savedMap) {
                    return map
                }
            }
            return [:]
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: USER_ID_MAPPING_ID_KEY)
            }
        }
    }
    static var idChatBoxMap: [UUID: ChatBox] {
        get {
            if let savedChatBoxesMapData = UserDefaults.standard.object(forKey: ID_CHATBOX_MAP_KEY) as? Data {
                if let chatBoxesMap = try? JSONDecoder().decode([UUID: ChatBox].self, from: savedChatBoxesMapData) {
                    return chatBoxesMap
                    
                }
            }
            return [:]
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: ID_CHATBOX_MAP_KEY)
            }
        }
    }
}


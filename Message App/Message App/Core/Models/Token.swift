//
//  Token.swift
//  Message App
//
//  Created by Dat Vu on 04/12/2022.
//

import Foundation

final class Token: Codable {
    var id: String
    var value: String
    var user: ResolveUUID
    
    init(id: String, value: String, user: ResolveUUID) {
        self.id = id
        self.value = value
        self.user = user
    }
}

//
//  Token.swift
//  MyMapKit
//
//  Created by Vũ Quý Đạt  on 24/12/2020.
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

//
//  File.swift
//  
//
//  Created by Dat Vu on 04/12/2022.
//

import Foundation

struct User: Codable {
    let id: UUID
    let name: String
    let username: String
    
    let email: String?
    let join: String?
    let phone: String?
    let birth: String?
    let siwaIdentifier: String?
    let avatar: String?
    let password: String?
    let country: String?
    let gender: Gender?
}

enum Gender: Int, Codable {
    case male, female, other
}

//
//  CreateMessage.swift
//
//
//  Created by Dat Vu on 28/11/2022.
//

import Fluent

struct CreateMessage: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("messages")
            .id()
            .field("sender", .string, .required)
            .field("message", .string, .required)
            .field("createdAt", .string)
            .field("chatBoxID", .uuid, .required, .references("chatBoxes", "id"))
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("messages").delete()
    }
}

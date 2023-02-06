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
            .field("createdAt", .string)
            .field("sender", .string, .required)
            .field("mediaType", .int64, .required)
            .field("content", .string, .required)
            .field("chatBoxId", .uuid, .required, .references("chatBoxes", "id"))
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("messages").delete()
    }
}

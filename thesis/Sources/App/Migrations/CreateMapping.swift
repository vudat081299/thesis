//
//  CreateMapping.swift
//  
//
//  Created by Dat Vu on 28/11/2022.
//

import Fluent

//struct CreateMapping: AsyncMigration {
//    func prepare(on database: Database) async throws {
//        try await database.schema("mappings")
//            .id()
//        //      .field("short", .string, .required)
//        //      .field("long", .string, .required)
//            .field("userID", .uuid, .required, .references("users", "id"))
//            .create()
//    }
//    
//    func revert(on database: Database) async throws {
//        try await database.schema("mappings").delete()
//    }
//}

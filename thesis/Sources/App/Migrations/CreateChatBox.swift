//
//  CreateChatBox.swift
//  
//
//  Created by Dat Vu on 28/11/2022.
//

import Fluent

struct CreateChatBox: AsyncMigration {
  func prepare(on database: Database) async throws {
      try await database.schema("chatBoxes")
      .id()
      .field("name", .string, .required)
      .field("avatar", .string)
      .create()
  }
  
  func revert(on database: Database) async throws {
      try await database.schema("chatBoxes").delete()
  }
}

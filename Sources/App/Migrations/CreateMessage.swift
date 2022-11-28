//
//  CreateMessage.swift
//
//
//  Created by Dat Vu on 28/11/2022.
//

import Fluent

struct CreateMessage: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    database.schema("messages")
      .id()
      .field("message", .string, .required)
      .field("chatBoxID", .uuid, .required, .references("chatBoxes", "id"))
      .create()
  }
  
  func revert(on database: Database) -> EventLoopFuture<Void> {
    database.schema("messages").delete()
  }
}

//
//  CreateChatBox.swift
//  
//
//  Created by Dat Vu on 28/11/2022.
//

import Fluent

struct CreateChatBox: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    database.schema("chatBoxes")
      .id()
      .field("name", .string, .required)
      .create()
  }
  
  func revert(on database: Database) -> EventLoopFuture<Void> {
    database.schema("chatBoxes").delete()
  }
}

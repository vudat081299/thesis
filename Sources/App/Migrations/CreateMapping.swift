//
//  CreateMapping.swift
//  
//
//  Created by Dat Vu on 28/11/2022.
//

import Fluent

struct CreateMapping: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    database.schema("mappings")
      .id()
      .field("short", .string, .required)
      .field("long", .string, .required)
      .field("userID", .uuid, .required, .references("users", "id"))
      .create()
  }
  
  func revert(on database: Database) -> EventLoopFuture<Void> {
    database.schema("mappings").delete()
  }
}

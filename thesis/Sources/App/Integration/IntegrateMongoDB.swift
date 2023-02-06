//
//  IntegrateMongoDB.swift
//  
//
//  Created by Dat Vu on 31/01/2023.
//

import Vapor
import MongoKitten

private struct MongoDBStorageKey: StorageKey {
    typealias Value = MongoDatabase
}

extension Application {
    public var mongoDB: MongoDatabase {
        get {
            // Not having MongoDB would be a serious programming error
            // Without MongoDB, the application does not function
            // Therefore force unwrapping is used
            storage[MongoDBStorageKey.self]!
        }
        set {
            storage[MongoDBStorageKey.self] = newValue
        }
    }
    
    public func initializeMongoDB(connectionString: String) throws {
        self.mongoDB = try MongoDatabase.lazyConnect(connectionString, on: self.eventLoopGroup)
    }
}

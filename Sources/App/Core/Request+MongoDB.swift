////
////  File.swift
////  
////
////  Created by Dat Vu on 29/01/2023.
////

import Vapor
import MongoKitten

extension Request {
    public var mongoDB: MongoDatabase {
        return application.mongoDB.hopped(to: eventLoop)
    }
}



//import MongoDBVapor
//
//struct ResolveFile: Content {
//    var _id: BSONObjectID?
//    var data: Data?
//}
//
//extension Request {
//    /// Convenience extension for obtaining a collection.
//    var fileCollection: MongoCollection<ResolveFile> {
//        let collectionName = "fileCollection"
//        return self.application.mongoDB.client.db("home").collection(collectionName, withType: ResolveFile.self)
//    }
//    
//    func writeFile() async throws -> String {
//        var newFile = try self.content.decode(ResolveFile.self)
//        newFile._id = BSONObjectID()
//        do {
//            try await fileCollection.insertOne(newFile)
//            guard
//    //            let data = newFile.data,
//                let fileObjectId = newFile._id?.hex
//            else {
//                throw Abort(.notAcceptable, reason: "Failed to save new kitten!")
//            }
//            return fileObjectId
//        } catch {
//            // Give a more helpful error message in case of a duplicate key error.
//            if let err = error as? MongoError.WriteError, err.writeFailure?.code == 11000 {
//                throw Abort(.conflict, reason: "A kitten with the name \(String(describing: newFile._id)) already exists!")
//            }
//            throw Abort(.internalServerError, reason: "Failed to save new kitten: \(error)")
//        }
//    }
//    
//    /// Constructs a document using the name from this request which can be used a filter for MongoDB
//    /// reads/updates/deletions.
//    func objectIdFilter() throws -> BSONDocument {
//        // We only call this method from request handlers that have name parameters so the value
//        // will always be available.
//        guard let id = self.parameters.get("objectId")
//        else {
//            throw Abort(.internalServerError, reason: "Request unexpectedly missing name parameter")
//        }
//        let objectId = try BSONObjectID(id)
//        return ["_id": .objectID(objectId)]
//    }
//    
//    func readFile() async throws -> Response {
//        let idFilter = try self.objectIdFilter()
//        guard let file = try await self.fileCollection.findOne(idFilter),
//              let data = file.data
//        else {
//            throw Abort(.notFound, reason: "No kitten with matching name")
//        }
//        return Response(body: Response.Body(data: data))
//    }
//}

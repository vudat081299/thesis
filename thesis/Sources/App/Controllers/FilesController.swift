//
//  FilesController.swift
//
//
//  Created by Dat Vu on 29/01/2023.
//

import Vapor
import MongoKitten

struct ResolveId: Content {
    let id: String
}

struct ResolveFile: Content {
    var _id: ObjectId?
    var data: Data?
}

struct FilesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let mediasRoutes = routes.grouped("api", "files")
        
        mediasRoutes.get(":objectId", use: getFileHandler)
        mediasRoutes.post(use: postFileHandler)
    }
    
    func getFileHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        guard let fileObjectId = req.parameters.get("objectId", as: ObjectId.self) else {
            throw Abort(.notFound)
        }
        
        return FilesController.readFile(byId: fileObjectId, inDatabase: req.mongoDB).map { data in
            return Response(body: Response.Body(data: data))
        }
    }
    func postFileHandler(_ req: Request) throws -> EventLoopFuture<ResolveId> {
        let newFile = try req.content.decode(ResolveFile.self)
        let fileObjectId: EventLoopFuture<ObjectId?>

        if let data = newFile.data, !data.isEmpty {
            // Upload the attached file to GridFS
            fileObjectId = FilesController.uploadFile(data, inDatabase: req.mongoDB).map { fileObjectId in
                // This is needed to map the EventLoopFuture from `ObjectId` to `ObjectId?`
                return fileObjectId
            }
        } else {
            fileObjectId = req.eventLoop.makeSucceededFuture(nil)
        }
        return fileObjectId.flatMapThrowing { id in
            guard let id = id else {
                throw Abort(.badRequest)
            }
            return ResolveId(id: id.hexString)
        }
    }
    
    
    
    
    // MARK: - File handler.
    static func uploadFile( _ data: Data, inDatabase database: MongoDatabase) -> EventLoopFuture<ObjectId> {
        let id = ObjectId()
        let gridFS = GridFSBucket(in: database)
        return gridFS.upload(data, id: id).map {
            return id
        }
    }
    static func readFile(byId id: ObjectId, inDatabase database: MongoDatabase) -> EventLoopFuture<Data> {
        let gridFS = GridFSBucket(in: database)
        return gridFS.findFile(byId: id).flatMap { file in
            guard let file = file else {
                return database.eventLoop.makeFailedFuture(Abort(.notFound))
            }
            return file.reader.readData()
        }
    }
    
//    func getFileHandler(req: Request) async throws -> Response {
//        guard let objectId = req.parameters.get("objectId")
//        else {
//            throw Abort(.notFound, reason: "Request unexpectedly missing name parameter")
//        }
//        let fileCollection = req.mongoDB["fileCollection"]
//        fileCollection.findOne("_id" == objectId).whenSuccess { (user: Document?) in
//            guard let user = user else {
//                return Response
//            }
//            return Response(body: Response.Body(data: user["Data"] as! Data))
//        }
//    }
//    func postFileHandler(req: Request) async throws -> String {
//        var newFile = try req.content.decode(ResolveFile.self)
//        newFile._id = ObjectId()
//        let fileCollection = req.mongoDB["fileCollection"]
//        let fileDocument: Document = ["_id": newFile._id, "data": newFile.data]
//
//        let insertResult: EventLoopFuture<InsertReply> = fileCollection.insert(fileDocument)
//
//        insertResult.whenSuccess { _ in
//            print("Inserted!")
//        }
//
//        insertResult.whenFailure { error in
//            print("Insertion failed", error)
//        }
//
//        guard let fileObjectId = newFile._id?.hexString else {
//            throw Abort(.notFound, reason: "Failed to save new kitten!")
//        }
//        return fileObjectId
//
////        var newFile = try self.content.decode(ResolveFile.self)
////        newFile._id = BSONObjectID()
////        do {
////            try await fileCollection.insertOne(newFile)
////            guard
////                //            let data = newFile.data,
////                let fileObjectId = newFile._id?.hex
////            else {
////                throw Abort(.notAcceptable, reason: "Failed to save new kitten!")
////            }
////            return fileObjectId
////        } catch {
////            // Give a more helpful error message in case of a duplicate key error.
////            if let err = error as? MongoError.WriteError, err.writeFailure?.code == 11000 {
////                throw Abort(.conflict, reason: "A kitten with the name \(String(describing: newFile._id)) already exists!")
////            }
////            throw Abort(.internalServerError, reason: "Failed to save new kitten: \(error)")
////        }
//    }
}

////
////  FilesController.swift
////
////
////  Created by Dat Vu on 29/01/2023.
////
//
//import Vapor
//import MongoKitten
//
//struct FilesController: RouteCollection {
//    func boot(routes: RoutesBuilder) throws {
//        let mediasRoutes = routes.grouped("api", "files")
//        
//        mediasRoutes.get(":objectId", use: getFileHandler)
//        mediasRoutes.post(use: postFileHandler)
//    }
//    
//    func getFileHandler(req: Request) async throws -> Response {
//        try await req.readFile()
//    }
//    func postFileHandler(req: Request) async throws -> String {
//        try await req.writeFile()
//    }
//}

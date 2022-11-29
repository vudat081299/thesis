//
//  MappingsController.swift
//  
//
//  Created by Dat Vu on 28/11/2022.
//

import Vapor
import Fluent

struct MappingsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let mappingsRoutes = routes.grouped("api", "mappings")
        mappingsRoutes.get(use: getAllHandler)
        mappingsRoutes.get(":mappingID", use: getHandler)
        //    mappingsRoutes.get("search", use: searchHandler)
        mappingsRoutes.get("first", use: getFirstHandler)
        //    mappingsRoutes.get("sorted", use: sortedHandler)
        mappingsRoutes.get(":mappingID", "user", use: getUserHandler)
        mappingsRoutes.get(":mappingID", "chatBoxes", use: getchatBoxesHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = mappingsRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.delete(":mappingID", use: deleteHandler)
        tokenAuthGroup.put(":mappingID", use: updateHandler)
        tokenAuthGroup.post(":mappingID", "chatBoxes", ":chatBoxID", use: addchatBoxesHandler)
        tokenAuthGroup.delete(":mappingID", "chatBoxes", ":chatBoxID", use: removechatBoxesHandler)
    }
    
    func getAllHandler(_ req: Request) -> EventLoopFuture<[Mapping]> {
        Mapping.query(on: req.db).all()
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Mapping> {
//        let data = try req.content.decode(CreateMappingData.self)
        let user = try req.auth.require(User.self)
        let mapping = try Mapping(userID: user.requireID())
        return mapping.save(on: req.db).map { mapping }
    }
    
    func getHandler(_ req: Request) -> EventLoopFuture<Mapping> {
        Mapping.find(req.parameters.get("mappingID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<Mapping> {
        let updateData = try req.content.decode(CreateMappingData.self)
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        return Mapping.find(req.parameters.get("mappingID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { mapping in
//        acronym.short = updateData.short
//        acronym.long = updateData.long
                mapping.$user.id = userID
                return mapping.save(on: req.db).map {
                    mapping
                }
            }
    }
    
    func deleteHandler(_ req: Request)
    -> EventLoopFuture<HTTPStatus> {
        Mapping.find(req.parameters.get("mappingID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { mapping in
                mapping.delete(on: req.db)
                    .transform(to: .noContent)
            }
    }
    
    //  func searchHandler(_ req: Request) throws -> EventLoopFuture<[Mapping]> {
    //    guard let searchTerm = req
    //      .query[String.self, at: "term"] else {
    //      throw Abort(.badRequest)
    //    }
    //    return Mapping.query(on: req.db).group(.or) { or in
    //      or.filter(\.$short == searchTerm)
    //      or.filter(\.$long == searchTerm)
    //    }.all()
    //  }
    
    func getFirstHandler(_ req: Request) -> EventLoopFuture<Mapping> {
        return Mapping.query(on: req.db)
            .first()
            .unwrap(or: Abort(.notFound))
    }
    
    //  func sortedHandler(_ req: Request) -> EventLoopFuture<[Mapping]> {
    //    return Mapping.query(on: req.db).sort(\.$short, .ascending).all()
    //  }
    
    func getUserHandler(_ req: Request) -> EventLoopFuture<User.Public> {
        Mapping.find(req.parameters.get("mappingID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { mapping in
                mapping.$user.get(on: req.db).convertToPublic()
            }
    }
    
    func addchatBoxesHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
        let mappingQuery = Mapping.find(req.parameters.get("mappingID"), on: req.db).unwrap(or: Abort(.notFound))
        let chatBoxQuery = ChatBox.find(req.parameters.get("chatBoxID"), on: req.db).unwrap(or: Abort(.notFound))
        return mappingQuery.and(chatBoxQuery).flatMap { mapping, chatBox in
            mapping.$chatBoxes.attach(chatBox, on: req.db).transform(to: .created)
        }
    }
    
    func getchatBoxesHandler(_ req: Request) -> EventLoopFuture<[ChatBox]> {
        Mapping.find(req.parameters.get("mappingID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { mapping in
                mapping.$chatBoxes.query(on: req.db).all()
            }
    }
    
    func removechatBoxesHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
        let mappingQuery = Mapping.find(req.parameters.get("mappingID"), on: req.db).unwrap(or: Abort(.notFound))
        let chatBoxQuery = ChatBox.find(req.parameters.get("chatBoxID"), on: req.db).unwrap(or: Abort(.notFound))
        return mappingQuery.and(chatBoxQuery).flatMap { mapping, chatBox in
            mapping.$chatBoxes.detach(chatBox, on: req.db).transform(to: .noContent)
        }
    }
}

struct CreateMappingData: Content {
    let short: String
    let long: String
}

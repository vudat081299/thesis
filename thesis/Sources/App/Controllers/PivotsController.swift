//
//  PivotsController.swift
//  
//
//  Created by Dat Vu on 29/11/2022.
//

import Vapor

struct PivotsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let chatBoxesRoute = routes.grouped("api", "mapping", "pivot")
        
        chatBoxesRoute.get(use: getAllChatboxMembersHandler)
        chatBoxesRoute.delete(":id", use: deleteMappingPivotHandler)
    }
    
    
    // MARK: - Get
    func getAllChatboxMembersHandler(_ req: Request) async throws -> [ChatboxMembers] {
        try await ChatboxMembers.query(on: req.db).all()
    }
    
    
    // MARK: - Delete
    func deleteMappingPivotHandler(_ req: Request) async throws -> HTTPStatus {
        guard let mapping = try await ChatboxMembers.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await mapping.delete(on: req.db)
        return .noContent
    }
    
}

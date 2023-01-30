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
        chatBoxesRoute.get(use: getMappingPivotAllHandler)
        chatBoxesRoute.delete(":id", use: deleteMappingPivotHandler)
        
    }
    
    
    // MARK: - Get
    func getMappingPivotAllHandler(_ req: Request) async throws -> [MappingChatBoxPivot] {
        try await MappingChatBoxPivot.query(on: req.db).all()
    }
    
    
    // MARK: - Delete
    func deleteMappingPivotHandler(_ req: Request) async throws -> HTTPStatus {
        guard let mapping = try await MappingChatBoxPivot.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await mapping.delete(on: req.db)
        return .noContent
    }
    
}

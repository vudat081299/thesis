import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index", ["title": "Hello Vapor!"])
    }
    
    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    try app.register(collection: TodoController())
    try app.register(collection: UsersController())
    try app.register(collection: MappingsController())
    try app.register(collection: ChatBoxesController())
    try app.register(collection: MessagesController())
    try app.register(collection: PivotsController())
    try app.register(collection: FilesController())
    
}

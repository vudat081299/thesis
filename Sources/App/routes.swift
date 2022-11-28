import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index", ["title": "Hello Vapor!"])
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    
    
    // MARK: - WebSocket
    app.webSocket("echo") { req, ws in
        // Connected WebSocket.
        print(ws)
    }

    try app.register(collection: TodoController())
}

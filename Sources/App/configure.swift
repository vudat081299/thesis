import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    
    // MARK: - Middleware
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(app.sessions.middleware)
    
    
    
    // MARK: - Database configuration
    let databaseName: String
    let databasePort: Int
    if (app.environment == .testing) {
      databaseName = "vapor-test"
      if let testPort = Environment.get("DATABASE_PORT") {
        databasePort = Int(testPort) ?? 5433
      } else {
        databasePort = 5433
      }
    } else {
      databaseName = "vapor_database"
      databasePort = 5432
    }
    
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
//        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
        port: databasePort,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
//        database: Environment.get("DATABASE_NAME") ?? "vapor_database"
        database: Environment.get("DATABASE_NAME") ?? databaseName
    ), as: .psql)
    
    app.migrations.add(CreateTodo())
    app.migrations.add(CreateUser())
    app.migrations.add(CreateMapping())
    app.migrations.add(CreateChatBox())
    app.migrations.add(CreateMapppingChatBoxPivot())
    app.migrations.add(CreateMessage())
    app.migrations.add(CreateToken())
    app.migrations.add(CreateAdminUser())
    
    
    
    // MARK: - App's configuration
    app.logger.logLevel = .debug
    try app.autoMigrate().wait()
    app.views.use(.leaf)
    
    // register routes
    try routes(app)
}

import Fluent
import FluentPostgresDriver
import Leaf
import Vapor
//import MongoDBVapor
import FluentMongoDriver

// configures your application
public func configure(_ app: Application) throws {
    
    // MARK: - Middleware
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(app.sessions.middleware)
    
    
    // MARK: - Config http server.
    let host = "192.168.1.24"
    app.http.server.configuration.hostname = host
    app.http.server.configuration.port = 8080
    app.routes.defaultMaxBodySize = "20mb"
    
    
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
    
    
    // MARK: - Connect MongoDB.
    /// Run MongoDB on Docker
//    docker run --name mongodb -d -p 27017:27017 mongo

    /// MongoKitten package usage
    try app.databases.use(.mongo(connectionString: "mongodb://localhost:27017/mongo"), as: .mongo)
////    let connectionString = Environment.get("MONGODB") ?? "MONGODB=mongodb://\(host):27017,\(host):27018,\(host):27019/thesis"
//   guard let connectionString = Environment.get("MONGODB") else {
//        fatalError("No MongoDB connection string is available in .env")
//    }
//    // connectionString should be MONGODB=mongodb://localhost:27017,localhost:27018,localhost:27019/social-messaging-server
//    print(connectionString)
    try app.initializeMongoDB(connectionString: "mongodb://localhost:27017/mongo")
    
    // Use `ExtendedJSONEncoder` and `ExtendedJSONDecoder` for encoding/decoding `Content`. We use extended JSON both
    // here and on the frontend to ensure all MongoDB type information is correctly preserved.
    // See: https://docs.mongodb.com/manual/reference/mongodb-extended-json
    // Note that for _encoding_ content, this encoder only gets used for the REST API methods, since Leaf uses its own
    // custom encoder to encode data for rendering in Leaf views.
    
    /// mongo-swift-driver  package usage
//    ContentConfiguration.global.use(encoder: ExtendedJSONEncoder(), for: .json)
//    ContentConfiguration.global.use(decoder: ExtendedJSONDecoder(), for: .json)
    
    
    app.migrations.add(CreateTodo())
    app.migrations.add(CreateUser())
    app.migrations.add(CreateChatBox())
    app.migrations.add(CreateChatboxMembers())
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

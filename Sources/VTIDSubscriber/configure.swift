import NIOSSL
import Fluent
import FluentMySQLDriver
import Leaf
import LilyFeedKit
import Vapor
import WebSubSubscriber

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(.mysql(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? MySQLConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database"
    ), as: .mysql)

    app.views.use(.leaf)

    app.migrations.add(CreateSubscriptionsTable())
    app.migrations.add(CreateYoutubeVideosTable())
    
    app.commands.use(WebSubSubscriber.Subscribe(), as: "subscribe")
    app.commands.use(WebSubSubscriber.Unsubscribe(), as: "unsubscribe")
    
    app.middleware.use(app.sessions.middleware)

    // register routes
    try routes(app)
}

import Fluent
import ImperialGoogle
import LilyFeedKit
import Vapor

func routes(_ app: Application) throws {
    
    try app.register(collection: SubscriberController())
    try app.register(collection: SubscriptionController())
    try app.register(collection: YoutubeVideoController())
    
    try app.routes.oAuth(
        from: Google.self,
        authenticate: "google-oauth",
        callback: "\(Environment.get("WEBSUB_HOST") ?? "")/google-oauth-complete",
        scope: [
            "email",
            "profile",
            "https://www.googleapis.com/auth/spreadsheets.readonly",
        ],
        redirect: "\(Environment.get("WEBSUB_PATH") ?? "")/oauth-token"
    )
    
    app.get("oauth-token") { req in
        return [
            "access-token": try req.accessToken()
        ]
    }
    
}

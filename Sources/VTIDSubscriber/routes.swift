import Fluent
import LilyFeedKit
import Vapor

func routes(_ app: Application) throws {
    
    try app.register(collection: SubscriberController())
    try app.register(collection: SubscriptionController())
    try app.register(collection: YoutubeVideoController())
    
}

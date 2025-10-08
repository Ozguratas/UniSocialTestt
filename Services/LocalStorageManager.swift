import Foundation

class LocalStorageManager {
    static let shared = LocalStorageManager()
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {}
    
    private enum Keys {
        static let currentUser = "currentUser"
        static let isAuthenticated = "isAuthenticated"
        static let cachedRoutes = "cachedRoutes"
        static let cachedEvents = "cachedEvents"
        static let inviteKeys = "inviteKeys"
        static let forumPosts = "forumPosts"
        static let forumComments = "forumComments"
        static let feedItems = "feedItems"
        static let feedComments = "feedItemComments"
        static let conversations = "conversations"
        static let messages = "messages"
        static let reviews = "reviews"
        static let achievements = "cachedAchievements"
        static let allUsers = "cachedAllUsers"
        static let friendRequests = "cachedFriendRequests"
    }
    
    // MARK: - User Session
    func saveUserSession(_ user: User) {
        if let encoded = try? encoder.encode(user) {
            defaults.set(encoded, forKey: Keys.currentUser)
            defaults.set(true, forKey: Keys.isAuthenticated)
            Logger.info("User session saved: \(user.email)")
        }
    }
    
    func loadUserSession() -> User? {
        guard let data = defaults.data(forKey: Keys.currentUser),
              let user = try? decoder.decode(User.self, from: data) else {
            return nil
        }
        return user
    }
    
    func isAuthenticated() -> Bool {
        return defaults.bool(forKey: Keys.isAuthenticated)
    }
    
    func clearSession() {
        defaults.removeObject(forKey: Keys.currentUser)
        defaults.set(false, forKey: Keys.isAuthenticated)
        Logger.info("Session cleared")
    }
    
    // MARK: - Routes Cache
    func cacheRoutes(_ routes: [Route]) {
        if let encoded = try? encoder.encode(routes) {
            defaults.set(encoded, forKey: Keys.cachedRoutes)
        }
    }
    
    func loadCachedRoutes() -> [Route] {
        guard let data = defaults.data(forKey: Keys.cachedRoutes),
              let routes = try? decoder.decode([Route].self, from: data) else {
            return []
        }
        return routes
    }
    
    // MARK: - Events Cache
    func cacheEvents(_ events: [Event]) {
        if let encoded = try? encoder.encode(events) {
            defaults.set(encoded, forKey: Keys.cachedEvents)
        }
    }
    
    func loadCachedEvents() -> [Event] {
        guard let data = defaults.data(forKey: Keys.cachedEvents),
              let events = try? decoder.decode([Event].self, from: data) else {
            return []
        }
        return events
    }
    
    // MARK: - Invite Keys
    func cacheInviteKeys(_ keys: [InviteKey]) {
        if let encoded = try? encoder.encode(keys) {
            defaults.set(encoded, forKey: Keys.inviteKeys)
        }
    }
    
    func loadCachedInviteKeys() -> [InviteKey] {
        guard let data = defaults.data(forKey: Keys.inviteKeys),
              let keys = try? decoder.decode([InviteKey].self, from: data) else {
            return []
        }
        return keys
    }
    
    // MARK: - Forum Posts Cache
    func cacheForumPosts(_ posts: [ForumPost]) {
        if let encoded = try? encoder.encode(posts) {
            defaults.set(encoded, forKey: Keys.forumPosts)
        }
    }
    
    func loadCachedForumPosts() -> [ForumPost] {
        guard let data = defaults.data(forKey: Keys.forumPosts),
              let posts = try? decoder.decode([ForumPost].self, from: data) else {
            return []
        }
        return posts
    }
    
    // MARK: - Forum Comments Cache
    func cacheForumComments(_ comments: [ForumComment]) {
        if let encoded = try? encoder.encode(comments) {
            defaults.set(encoded, forKey: Keys.forumComments)
        }
    }
    
    func loadCachedForumComments() -> [ForumComment] {
        guard let data = defaults.data(forKey: Keys.forumComments),
              let comments = try? decoder.decode([ForumComment].self, from: data) else {
            return []
        }
        return comments
    }
    
    // MARK: - Feed Items Cache
    func cacheFeedItems(_ items: [FeedItem]) {
        if let encoded = try? encoder.encode(items) {
            defaults.set(encoded, forKey: Keys.feedItems)
        }
    }
    
    func loadCachedFeedItems() -> [FeedItem] {
        guard let data = defaults.data(forKey: Keys.feedItems),
              let items = try? decoder.decode([FeedItem].self, from: data) else {
            return []
        }
        return items
    }
    
    // MARK: - Feed Comments Cache (FeedItemComment)
    func cacheFeedComments(_ comments: [FeedItemComment]) {
        if let encoded = try? encoder.encode(comments) {
            defaults.set(encoded, forKey: Keys.feedComments)
        }
    }
    
    func loadCachedFeedComments() -> [FeedItemComment] {
        guard let data = defaults.data(forKey: Keys.feedComments),
              let comments = try? decoder.decode([FeedItemComment].self, from: data) else {
            return []
        }
        return comments
    }
    
    // MARK: - Conversations Cache
    func cacheConversations(_ conversations: [Conversation]) {
        if let encoded = try? encoder.encode(conversations) {
            defaults.set(encoded, forKey: Keys.conversations)
        }
    }
    
    func loadCachedConversations() -> [Conversation] {
        guard let data = defaults.data(forKey: Keys.conversations),
              let conversations = try? decoder.decode([Conversation].self, from: data) else {
            return []
        }
        return conversations
    }
    
    // MARK: - Messages Cache
    func cacheMessages(_ messages: [Message]) {
        if let encoded = try? encoder.encode(messages) {
            defaults.set(encoded, forKey: Keys.messages)
        }
    }
    
    func loadCachedMessages() -> [Message] {
        guard let data = defaults.data(forKey: Keys.messages),
              let messages = try? decoder.decode([Message].self, from: data) else {
            return []
        }
        return messages
    }
    
    // MARK: - Reviews Cache
    func cacheReviews(_ reviews: [Review]) {
        if let encoded = try? encoder.encode(reviews) {
            defaults.set(encoded, forKey: Keys.reviews)
        }
    }
    
    func loadCachedReviews() -> [Review] {
        guard let data = defaults.data(forKey: Keys.reviews),
              let reviews = try? decoder.decode([Review].self, from: data) else {
            return []
        }
        return reviews
    }
    
    // MARK: - Achievements Cache
    func cacheAchievements(_ achievements: [Achievement]) {
        if let encoded = try? encoder.encode(achievements) {
            defaults.set(encoded, forKey: Keys.achievements)
        }
    }
    
    func loadCachedAchievements() -> [Achievement] {
        guard let data = defaults.data(forKey: Keys.achievements),
              let achievements = try? decoder.decode([Achievement].self, from: data) else {
            return []
        }
        return achievements
    }
    
    // MARK: - All Users Cache
    func cacheAllUsers(_ users: [User]) {
        if let encoded = try? encoder.encode(users) {
            defaults.set(encoded, forKey: Keys.allUsers)
        }
    }
    
    func loadCachedAllUsers() -> [User] {
        guard let data = defaults.data(forKey: Keys.allUsers),
              let users = try? decoder.decode([User].self, from: data) else {
            return []
        }
        return users
    }
    
    // MARK: - Friend Requests Cache
    func cacheFriendRequests(_ requests: [FriendRequest]) {
        if let encoded = try? encoder.encode(requests) {
            defaults.set(encoded, forKey: Keys.friendRequests)
        }
    }
    
    func loadCachedFriendRequests() -> [FriendRequest] {
        guard let data = defaults.data(forKey: Keys.friendRequests),
              let requests = try? decoder.decode([FriendRequest].self, from: data) else {
            return []
        }
        return requests
    }
}

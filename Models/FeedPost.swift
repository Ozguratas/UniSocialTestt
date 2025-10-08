import Foundation

struct FeedPost: Identifiable, Codable {
    let id: String
    let authorId: String
    let authorName: String
    let content: String
    let imageUrl: String?
    var likes: [String]
    var commentCount: Int
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        authorId: String,
        authorName: String,
        content: String,
        imageUrl: String? = nil,
        likes: [String] = [],
        commentCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.authorId = authorId
        self.authorName = authorName
        self.content = content
        self.imageUrl = imageUrl
        self.likes = likes
        self.commentCount = commentCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct PostComment: Identifiable, Codable {
    let id: String
    let postId: String
    let authorId: String
    let authorName: String
    let content: String
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        postId: String,
        authorId: String,
        authorName: String,
        content: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.postId = postId
        self.authorId = authorId
        self.authorName = authorName
        self.content = content
        self.createdAt = createdAt
    }
}

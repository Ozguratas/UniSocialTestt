import Foundation

struct Story: Identifiable, Codable {
    let id: String
    let userId: String
    let userName: String
    let imageUrl: String?
    let videoUrl: String?
    let createdAt: Date
    let expiresAt: Date
    var views: [String]
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        userName: String,
        imageUrl: String? = nil,
        videoUrl: String? = nil,
        createdAt: Date = Date(),
        expiresAt: Date = Date().addingTimeInterval(24 * 60 * 60), // 24 hours
        views: [String] = []
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.imageUrl = imageUrl
        self.videoUrl = videoUrl
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.views = views
    }
    
    var isExpired: Bool {
        return Date() > expiresAt
    }
}

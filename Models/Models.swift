import Foundation
import CoreLocation

// MARK: - User
struct User: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var email: String
    var university: String
    var profileImage: String
    var rating: Double
    var totalRides: Int
    var phoneNumber: String
    var isVerified: Bool
    var bio: String
    var interests: [String]
    var friends: [String]
    var blockedUsers: [String]
    var gender: String
    var department: String
    var graduationYear: Int
    var level: Int
    var xp: Int
    var achievements: [String]
    var totalReviews: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - InviteKey
struct InviteKey: Codable, Identifiable {
    let id: String
    let key: String
    let createdBy: String
    let createdAt: Date
    var isUsed: Bool
    var usedBy: String?
    var usedByName: String?
    var usedByEmail: String?
    var usedAt: Date?
    var expiresAt: Date?
    var maxUses: Int
    var currentUses: Int
}

// MARK: - Route
struct Route: Identifiable, Codable, Hashable {
    let id: String
    let driverId: String
    var driverName: String
    var driverRating: Double
    var driverGender: String
    let startLocation: String
    let endLocation: String
    var startLatitude: Double
    var startLongitude: Double
    var endLatitude: Double
    var endLongitude: Double
    let departureTime: Date
    var availableSeats: Int
    var passengers: [String]
    let vehicleInfo: String
    var isActive: Bool
    var isRecurring: Bool
    var recurringDays: [String]
    var preferences: RoutePreferences
    var meetingPoint: String
    var estimatedDuration: Int
    var distance: Double
    var note: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Route, rhs: Route) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - EventCategory
enum EventCategory: String, Codable, CaseIterable {
    case social = "Sosyal"
    case sports = "Spor"
    case academic = "Akademik"
    case cultural = "Kültür & Sanat"
    case volunteer = "Gönüllülük"
    case other = "Diğer"
}

// MARK: - Event
struct Event: Identifiable, Codable, Hashable {
    let id: String
    let creatorId: String
    var creatorName: String
    let title: String
    let description: String
    let location: String
    let eventTime: Date
    var participants: [String]
    let maxParticipants: Int
    var category: EventCategory
    var requirements: [String]
    
    // Backward compatibility için computed properties
    var organizerName: String { creatorName }
    var date: Date { eventTime }
    
    init(
        id: String = UUID().uuidString,
        creatorId: String,
        creatorName: String,
        title: String,
        description: String,
        location: String,
        eventTime: Date,
        participants: [String] = [],
        maxParticipants: Int,
        category: EventCategory = .social,
        requirements: [String] = []
    ) {
        self.id = id
        self.creatorId = creatorId
        self.creatorName = creatorName
        self.title = title
        self.description = description
        self.location = location
        self.eventTime = eventTime
        self.participants = participants
        self.maxParticipants = maxParticipants
        self.category = category
        self.requirements = requirements
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Event, rhs: Event) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - ForumCategory
enum ForumCategory: String, Codable, CaseIterable {
    case general = "Genel"
    case study = "Ders & Sınav"
    case social = "Sosyal"
    case housing = "Ev & Konaklama"
    case food = "Yemek"
    case tech = "Teknoloji"
    case sports = "Spor"
    case culture = "Kültür & Sanat"
}

// MARK: - ForumPost
struct ForumPost: Identifiable, Codable, Hashable {
    let id: String
    let authorId: String
    var authorName: String
    let category: ForumCategory
    let title: String
    let content: String
    let createdAt: Date
    var likes: [String]
    var commentCount: Int
    var isPinned: Bool
    var tags: [String]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ForumPost, rhs: ForumPost) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - ForumComment
struct ForumComment: Identifiable, Codable, Hashable {
    let id: String
    let postId: String
    let authorId: String
    var authorName: String
    let content: String
    let createdAt: Date
    var likes: [String]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ForumComment, rhs: ForumComment) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - FeedType
enum FeedType: String, Codable {
    case newRoute = "Yeni Güzergah"
    case newEvent = "Yeni Etkinlik"
    case newForumPost = "Forum Gönderisi"
    case achievement = "Başarı"
    case announcement = "Duyuru"
}

// MARK: - FeedItem
struct FeedItem: Identifiable, Codable, Hashable {
    let id: String
    let type: FeedType
    let userId: String
    var userName: String
    let title: String
    let content: String
    let createdAt: Date
    var likes: [String]
    var commentCount: Int
    var imageUrl: String?
    var relatedId: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FeedItem, rhs: FeedItem) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - FeedItemComment (renamed from FeedComment to avoid conflict)
struct FeedItemComment: Identifiable, Codable, Hashable {
    let id: String
    let feedItemId: String
    let authorId: String
    var authorName: String
    let content: String
    let createdAt: Date
    var likes: [String]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FeedItemComment, rhs: FeedItemComment) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - MessageType
enum MessageType: String, Codable {
    case text = "text"
    case image = "image"
    case location = "location"
    case routeShare = "routeShare"
    case eventShare = "eventShare"
}

// MARK: - Message
struct Message: Identifiable, Codable, Hashable {
    let id: String
    let conversationId: String
    let senderId: String
    var senderName: String
    let content: String
    let type: MessageType
    let createdAt: Date
    var isRead: Bool
    var imageUrl: String?
    var relatedId: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - ConversationType
enum ConversationType: String, Codable {
    case direct = "direct"
    case group = "group"
}

// MARK: - Conversation
struct Conversation: Identifiable, Codable, Hashable {
    let id: String
    let type: ConversationType
    var participants: [String]
    var participantNames: [String: String]
    var lastMessage: String
    var lastMessageTime: Date
    var unreadCount: Int
    var groupName: String?
    var groupImage: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - ReviewCategory
enum ReviewCategory: String, Codable, CaseIterable {
    case punctuality = "Dakiklik"
    case communication = "İletişim"
    case cleanliness = "Temizlik"
    case driving = "Sürüş"
    case friendliness = "Dostluk"
}

// MARK: - ReviewCategories
struct ReviewCategories: Codable {
    var safety: Double
    var punctuality: Double
    var communication: Double
    var cleanliness: Double
}

// MARK: - Review
struct Review: Identifiable, Codable {
    let id: String
    let reviewerId: String
    var reviewerName: String
    let reviewedUserId: String
    let routeId: String?
    let rating: Double
    let comment: String
    let categories: [ReviewCategory: Double]
    let createdAt: Date
}

// MARK: - AchievementCategory
enum AchievementCategory: String, Codable, CaseIterable {
    case social = "Sosyal"
    case travel = "Yolculuk"
    case event = "Etkinlik"
    case community = "Topluluk"
    case special = "Özel"
}

// MARK: - Achievement
struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let category: AchievementCategory
    let icon: String
    let requiredValue: Int
    var isUnlocked: Bool
    var unlockedAt: Date?
    var progress: Int
}

// MARK: - FriendRequestStatus
enum FriendRequestStatus: String, Codable {
    case pending = "Bekliyor"
    case accepted = "Kabul Edildi"
    case rejected = "Reddedildi"
}

// MARK: - FriendRequest
struct FriendRequest: Identifiable, Codable {
    let id: String
    let senderId: String
    var senderName: String
    let receiverId: String
    let createdAt: Date
    var status: FriendRequestStatus
}

// MARK: - Date Extension
extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: self, to: now)
        
        if let year = components.year, year > 0 {
            return year == 1 ? "1 yıl önce" : "\(year) yıl önce"
        }
        
        if let month = components.month, month > 0 {
            return month == 1 ? "1 ay önce" : "\(month) ay önce"
        }
        
        if let week = components.weekOfYear, week > 0 {
            return week == 1 ? "1 hafta önce" : "\(week) hafta önce"
        }
        
        if let day = components.day, day > 0 {
            return day == 1 ? "1 gün önce" : "\(day) gün önce"
        }
        
        if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 saat önce" : "\(hour) saat önce"
        }
        
        if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 dakika önce" : "\(minute) dakika önce"
        }
        
        return "Az önce"
    }
}

// MARK: - User Extensions
extension User {
    var isPhoneVerified: Bool {
        return SafetyManager.shared.isPhoneVerified(phoneNumber)
    }
    
    var hasEmergencyContacts: Bool {
        return !EmergencyManager.shared.emergencyContacts.isEmpty
    }
    
    var safetyScore: Double {
        var score = 0.0
        
        if isPhoneVerified { score += 20 }
        if isVerified { score += 20 }
        if hasEmergencyContacts { score += 15 }
        if rating >= 4.5 { score += 15 }
        if totalRides >= 10 { score += 15 }
        if totalReviews >= 5 { score += 15 }
        
        return score
    }
    
    var isDriver: Bool {
        return totalRides > 0
    }
}

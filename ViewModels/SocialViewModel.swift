import Foundation
import SwiftUI
import Combine

class SocialViewModel: ObservableObject {
    @Published var allUsers: [User] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var searchText = ""
    @Published var selectedInterests: Set<String> = []
    
    init() {
        loadUsers()
        loadFriendRequests()
        createSampleUsers()
    }
    
    func loadUsers() {  // private kaldırıldı
        let cached = LocalStorageManager.shared.loadCachedAllUsers()
        if !cached.isEmpty {
            self.allUsers = cached
        }
    }
    
    private func loadFriendRequests() {
        let cached = LocalStorageManager.shared.loadCachedFriendRequests()
        if !cached.isEmpty {
            self.friendRequests = cached
        }
    }
    
    private func createSampleUsers() {
        if allUsers.isEmpty {
            allUsers = [
                User(
                    id: "sample1",
                    name: "Ahmet Yılmaz",
                    email: "ahmet@itu.edu.tr",
                    university: "İTÜ",
                    profileImage: "person.circle.fill",
                    rating: 4.8,
                    totalRides: 15,
                    phoneNumber: "+90 555 111 1111",
                    isVerified: true,
                    bio: "Müzik ve spor tutkunu 🎵⚽",
                    interests: ["Müzik", "Spor", "Sinema"],
                    friends: [],
                    blockedUsers: [],
                    gender: "Erkek",
                    department: "Bilgisayar Mühendisliği",
                    graduationYear: 2025,
                    level: 5,
                    xp: 450,
                    achievements: ["first_ride", "first_friend"],
                    totalReviews: 12
                ),
                User(
                    id: "sample2",
                    name: "Zeynep Kaya",
                    email: "zeynep@itu.edu.tr",
                    university: "İTÜ",
                    profileImage: "person.circle.fill",
                    rating: 4.9,
                    totalRides: 22,
                    phoneNumber: "+90 555 222 2222",
                    isVerified: true,
                    bio: "Kitap okumayı ve gezmeyi seviyorum 📚✈️",
                    interests: ["Kitap", "Seyahat", "Fotoğrafçılık"],
                    friends: [],
                    blockedUsers: [],
                    gender: "Kadın",
                    department: "Endüstri Mühendisliği",
                    graduationYear: 2024,
                    level: 7,
                    xp: 680,
                    achievements: ["first_ride", "social_butterfly"],
                    totalReviews: 18
                ),
                User(
                    id: "sample3",
                    name: "Can Öztürk",
                    email: "can@itu.edu.tr",
                    university: "İTÜ",
                    profileImage: "person.circle.fill",
                    rating: 4.7,
                    totalRides: 10,
                    phoneNumber: "+90 555 333 3333",
                    isVerified: false,
                    bio: "Yeni mezun oldum, teknoloji meraklısı 💻",
                    interests: ["Teknoloji", "Oyun", "Müzik"],
                    friends: [],
                    blockedUsers: [],
                    gender: "Erkek",
                    department: "Elektrik-Elektronik Mühendisliği",
                    graduationYear: 2026,
                    level: 3,
                    xp: 280,
                    achievements: ["first_friend"],
                    totalReviews: 8
                )
            ]
            saveUsers()
        }
    }
    
    private func saveUsers() {
        LocalStorageManager.shared.cacheAllUsers(allUsers)
    }
    
    private func saveFriendRequests() {
        LocalStorageManager.shared.cacheFriendRequests(friendRequests)
    }
    
    // MARK: - Friend Requests
    
    func sendFriendRequest(from senderId: String, senderName: String, to receiverId: String) {
        // Check if request already exists
        let existingRequest = friendRequests.first { request in
            (request.senderId == senderId && request.receiverId == receiverId) ||
            (request.senderId == receiverId && request.receiverId == senderId)
        }
        
        if existingRequest != nil {
            Logger.warning("Friend request already exists")
            return
        }
        
        let newRequest = FriendRequest(
            id: UUID().uuidString,
            senderId: senderId,
            senderName: senderName,
            receiverId: receiverId,
            createdAt: Date(),
            status: .pending
        )
        
        friendRequests.append(newRequest)
        saveFriendRequests()
        Logger.info("Friend request sent from \(senderName) to user \(receiverId)")
    }
    
    // Overload for backward compatibility
    func sendFriendRequest(from senderId: String, to receiverId: String) {
        guard let sender = allUsers.first(where: { $0.id == senderId }) else {
            Logger.error("Sender not found: \(senderId)")
            return
        }
        sendFriendRequest(from: senderId, senderName: sender.name, to: receiverId)
    }
    
    func acceptFriendRequest(requestId: String, currentUser: inout User) {
        guard let index = friendRequests.firstIndex(where: { $0.id == requestId }) else { return }
        
        let request = friendRequests[index]
        friendRequests[index].status = .accepted
        
        // Add to friends list
        if !currentUser.friends.contains(request.senderId) {
            currentUser.friends.append(request.senderId)
        }
        
        // Add current user to sender's friends list
        if let senderIndex = allUsers.firstIndex(where: { $0.id == request.senderId }) {
            if !allUsers[senderIndex].friends.contains(currentUser.id) {
                allUsers[senderIndex].friends.append(currentUser.id)
            }
        }
        
        saveFriendRequests()
        saveUsers()
        Logger.info("Friend request accepted: \(request.id)")
    }
    
    func rejectFriendRequest(requestId: String) {
        guard let index = friendRequests.firstIndex(where: { $0.id == requestId }) else { return }
        friendRequests[index].status = .rejected
        saveFriendRequests()
        Logger.info("Friend request rejected: \(requestId)")
    }
    
    func getPendingRequests(for userId: String) -> [FriendRequest] {
        return friendRequests.filter { $0.receiverId == userId && $0.status == .pending }
    }
    
    func getSentRequests(from userId: String) -> [FriendRequest] {
        return friendRequests.filter { $0.senderId == userId && $0.status == .pending }
    }
    
    // MARK: - User Discovery
    
    func getRecommendedUsers(currentUserId: String, currentUserInterests: [String], currentUserFriends: [String]) -> [User] {
        return allUsers
            .filter { $0.id != currentUserId && !currentUserFriends.contains($0.id) }
            .filter { user in
                !user.interests.filter { currentUserInterests.contains($0) }.isEmpty
            }
            .sorted { user1, user2 in
                let common1 = Set(user1.interests).intersection(Set(currentUserInterests)).count
                let common2 = Set(user2.interests).intersection(Set(currentUserInterests)).count
                return common1 > common2
            }
    }
    
    func getDiscoverUsers(currentUserId: String, currentUserFriends: [String]) -> [User] {
        var users = allUsers.filter { $0.id != currentUserId && !currentUserFriends.contains($0.id) }
        
        if !searchText.isEmpty {
            users = users.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        if !selectedInterests.isEmpty {
            users = users.filter { user in
                !user.interests.filter { selectedInterests.contains($0) }.isEmpty
            }
        }
        
        return users
    }
    
    func getFriends(friendIds: [String]) -> [User] {
        return allUsers.filter { friendIds.contains($0.id) }
    }
    
    func getUser(by id: String) -> User? {
        return allUsers.first { $0.id == id }
    }
    
    func updateUser(_ user: User) {
        if let index = allUsers.firstIndex(where: { $0.id == user.id }) {
            allUsers[index] = user
            saveUsers()
        }
    }
    
    func removeFriend(userId: String, friendId: String) {
        // Remove from user's friends
        if let userIndex = allUsers.firstIndex(where: { $0.id == userId }) {
            allUsers[userIndex].friends.removeAll { $0 == friendId }
        }
        
        // Remove from friend's friends
        if let friendIndex = allUsers.firstIndex(where: { $0.id == friendId }) {
            allUsers[friendIndex].friends.removeAll { $0 == userId }
        }
        
        saveUsers()
        Logger.info("Friend removed: \(friendId) from \(userId)")
    }
    
    func blockUser(userId: String, blockedUserId: String) {
        if let index = allUsers.firstIndex(where: { $0.id == userId }) {
            if !allUsers[index].blockedUsers.contains(blockedUserId) {
                allUsers[index].blockedUsers.append(blockedUserId)
                // Also remove from friends if exists
                allUsers[index].friends.removeAll { $0 == blockedUserId }
                saveUsers()
                Logger.info("User blocked: \(blockedUserId) by \(userId)")
            }
        }
    }
    
    func unblockUser(userId: String, unblockedUserId: String) {
        if let index = allUsers.firstIndex(where: { $0.id == userId }) {
            allUsers[index].blockedUsers.removeAll { $0 == unblockedUserId }
            saveUsers()
            Logger.info("User unblocked: \(unblockedUserId) by \(userId)")
        }
    }
}

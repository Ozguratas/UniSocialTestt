import Foundation
import Combine

class FeedViewModel: ObservableObject {
    @Published var posts: [FeedPost] = []
    @Published var stories: [Story] = []
    @Published var feedItems: [FeedItem] = []
    @Published var feedComments: [FeedItemComment] = []
    @Published var selectedFilter: FeedType?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var postComments: [PostComment] = []
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadMockData()
        loadFeedData()
    }
    
    // MARK: - Feed Items
    
    var filteredFeed: [FeedItem] {
        if let filter = selectedFilter {
            return feedItems.filter { $0.type == filter }
        }
        return feedItems.sorted { $0.createdAt > $1.createdAt }
    }
    
    func refreshFeed() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.loadFeedData()
            self?.isLoading = false
        }
    }
    
    func toggleLike(feedItemId: String, userId: String) {
        guard let index = feedItems.firstIndex(where: { $0.id == feedItemId }) else { return }
        
        if feedItems[index].likes.contains(userId) {
            feedItems[index].likes.removeAll { $0 == userId }
        } else {
            feedItems[index].likes.append(userId)
        }
        
        LocalStorageManager.shared.cacheFeedItems(feedItems)
    }
    
    // ✅ DÜZELTME: Fonksiyon adı değiştirildi
    func getFeedItemComments(for feedItemId: String) -> [FeedItemComment] {
        return feedComments.filter { $0.feedItemId == feedItemId }
            .sorted { $0.createdAt < $1.createdAt }
    }
    
    func addFeedItemComment(feedItemId: String, authorId: String, authorName: String, content: String) {
        let comment = FeedItemComment(
            id: UUID().uuidString,
            feedItemId: feedItemId,
            authorId: authorId,
            authorName: authorName,
            content: content,
            createdAt: Date(),
            likes: []
        )
        
        feedComments.append(comment)
        
        // Update comment count
        if let index = feedItems.firstIndex(where: { $0.id == feedItemId }) {
            feedItems[index].commentCount += 1
        }
        
        LocalStorageManager.shared.cacheFeedComments(feedComments)
        LocalStorageManager.shared.cacheFeedItems(feedItems)
        Logger.info("Comment added to feed item: \(feedItemId)")
    }
    
    // MARK: - Posts
    
    func refreshPosts() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.loadMockData()
            self?.isLoading = false
        }
    }
    
    func createPost(authorId: String, authorName: String, content: String, imageUrl: String?) {
        let newPost = FeedPost(
            authorId: authorId,
            authorName: authorName,
            content: content,
            imageUrl: imageUrl
        )
        
        posts.insert(newPost, at: 0)
        Logger.info("Post created: \(newPost.id)")
    }
    
    func toggleLike(postId: String, userId: String) {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else { return }
        
        if posts[index].likes.contains(userId) {
            posts[index].likes.removeAll { $0 == userId }
        } else {
            posts[index].likes.append(userId)
        }
    }
    
    func deletePost(postId: String) {
        posts.removeAll { $0.id == postId }
    }
    
    // MARK: - Post Comments
    
    // ✅ DÜZELTME: Fonksiyon adı değiştirildi
    func getPostComments(for postId: String) -> [PostComment] {
        return postComments.filter { $0.postId == postId }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    func addPostComment(postId: String, authorId: String, authorName: String, content: String) {
        let comment = PostComment(
            postId: postId,
            authorId: authorId,
            authorName: authorName,
            content: content
        )
        
        postComments.append(comment)
        
        // Update comment count
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].commentCount += 1
        }
        
        Logger.info("Comment added to post: \(postId)")
    }
    
    // MARK: - Stories
    
    func createStory(userId: String, userName: String, imageUrl: String?, videoUrl: String?) {
        let story = Story(
            userId: userId,
            userName: userName,
            imageUrl: imageUrl,
            videoUrl: videoUrl
        )
        
        stories.insert(story, at: 0)
        Logger.info("Story created: \(story.id)")
    }
    
    func markStoryAsViewed(storyId: String, userId: String) {
        guard let index = stories.firstIndex(where: { $0.id == storyId }) else { return }
        
        if !stories[index].views.contains(userId) {
            stories[index].views.append(userId)
        }
    }
    
    // MARK: - Mock Data
    
    private func loadFeedData() {
        let cached = LocalStorageManager.shared.loadCachedFeedItems()
        if !cached.isEmpty {
            self.feedItems = cached
        }
        
        let cachedComments = LocalStorageManager.shared.loadCachedFeedComments()
        if !cachedComments.isEmpty {
            self.feedComments = cachedComments
        }
    }
    
    private func loadMockData() {
        // Mock Posts
        posts = [
            FeedPost(
                id: "1",
                authorId: "user1",
                authorName: "Ahmet Yılmaz",
                content: "Bugün kampüste harika bir gün geçirdim! 🎓 Yeni arkadaşlar edindim ve güzel sohbetler yaptık.",
                imageUrl: nil,
                likes: ["user2", "user3"],
                commentCount: 3,
                createdAt: Date().addingTimeInterval(-3600)
            ),
            FeedPost(
                id: "2",
                authorId: "user2",
                authorName: "Zeynep Kaya",
                content: "Yarın için güzergah paylaşımı yapıyorum. Kadıköy-Beşiktaş arası kimse var mı? 🚗",
                imageUrl: nil,
                likes: ["user1", "user4", "user5"],
                commentCount: 5,
                createdAt: Date().addingTimeInterval(-7200)
            ),
            FeedPost(
                id: "3",
                authorId: "user3",
                authorName: "Mehmet Demir",
                content: "Üniversite kütüphanesinde müthiş bir çalışma ortamı var! 📚✨",
                imageUrl: nil,
                likes: ["user1"],
                commentCount: 1,
                createdAt: Date().addingTimeInterval(-10800)
            ),
            FeedPost(
                id: "4",
                authorId: "user4",
                authorName: "Ayşe Şahin",
                content: "Bu hafta sonu piknik organizasyonu yapıyoruz, katılmak isteyen var mı? 🧺🌳",
                imageUrl: nil,
                likes: ["user2", "user3", "user5"],
                commentCount: 8,
                createdAt: Date().addingTimeInterval(-14400)
            ),
            FeedPost(
                id: "5",
                authorId: "user5",
                authorName: "Can Öztürk",
                content: "Yeni bir proje üzerinde çalışıyorum, tavsiyelere açığım! 💻",
                imageUrl: nil,
                likes: ["user1", "user2"],
                commentCount: 2,
                createdAt: Date().addingTimeInterval(-18000)
            )
        ]
        
        // Mock Stories
        stories = [
            Story(
                id: "s1",
                userId: "user1",
                userName: "Ahmet Yılmaz",
                imageUrl: nil,
                createdAt: Date().addingTimeInterval(-3600),
                views: ["user2"]
            ),
            Story(
                id: "s2",
                userId: "user2",
                userName: "Zeynep Kaya",
                imageUrl: nil,
                createdAt: Date().addingTimeInterval(-7200),
                views: []
            ),
            Story(
                id: "s3",
                userId: "user3",
                userName: "Mehmet Demir",
                imageUrl: nil,
                createdAt: Date().addingTimeInterval(-10800),
                views: ["user1", "user2"]
            )
        ]
        
        // Mock Post Comments
        postComments = [
            PostComment(
                postId: "1",
                authorId: "user2",
                authorName: "Zeynep Kaya",
                content: "Harika! Ben de oradaydım 😊"
            ),
            PostComment(
                postId: "1",
                authorId: "user3",
                authorName: "Mehmet Demir",
                content: "Keşke ben de gelebilseydim!"
            ),
            PostComment(
                postId: "2",
                authorId: "user1",
                authorName: "Ahmet Yılmaz",
                content: "Ben varım! Saat kaçta?"
            ),
            PostComment(
                postId: "2",
                authorId: "user4",
                authorName: "Ayşe Şahin",
                content: "Ben de katılabilirim 🚗"
            )
        ]
    }
}

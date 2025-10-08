import Foundation
import SwiftUI
import Combine

class ForumViewModel: ObservableObject {
    @Published var posts: [ForumPost] = []
    @Published var comments: [ForumComment] = []
    @Published var selectedCategory: ForumCategory?
    @Published var isLoading = false
    
    init() {
        loadPosts()
        loadComments()
        loadSampleData()
    }
    
    private func loadPosts() {
        let cached = LocalStorageManager.shared.loadCachedForumPosts()
        if !cached.isEmpty {
            self.posts = cached
        }
    }
    
    private func loadComments() {
        let cached = LocalStorageManager.shared.loadCachedForumComments()
        if !cached.isEmpty {
            self.comments = cached
        }
    }
    
    private func loadSampleData() {
        if posts.isEmpty {
            posts = [
                ForumPost(
                    id: "1",
                    authorId: "user1",
                    authorName: "Mehmet Yılmaz",
                    category: .general,
                    title: "Kantinde wifi çekmiyor mu?",
                    content: "Son 2 haftadır kantinde wifi çok yavaş. Sadece bende mi bu sorun?",
                    createdAt: Date().addingTimeInterval(-7200),
                    likes: ["user2", "user3"],
                    commentCount: 5,
                    isPinned: false,
                    tags: ["teknik", "kampüs"]
                ),
                ForumPost(
                    id: "2",
                    authorId: "user2",
                    authorName: "Ayşe Demir",
                    category: .study,
                    title: "Lineer Cebir final notları",
                    content: "Final öncesi ders notlarını paylaşmak isteyen var mı?",
                    createdAt: Date().addingTimeInterval(-3600),
                    likes: ["user1", "user3", "user4"],
                    commentCount: 8,
                    isPinned: true,
                    tags: ["matematik", "final"]
                )
            ]
            savePosts()
        }
        
        if comments.isEmpty {
            comments = [
                ForumComment(
                    id: "c1",
                    postId: "1",
                    authorId: "user2",
                    authorName: "Ali Kaya",
                    content: "Bende de aynı sorun var, özellikle öğle saatlerinde çok yavaş",
                    createdAt: Date().addingTimeInterval(-6000),
                    likes: ["user1"]
                ),
                ForumComment(
                    id: "c2",
                    postId: "1",
                    authorId: "user3",
                    authorName: "Zeynep Aydın",
                    content: "IT'ye mail attım, önümüzdeki hafta düzelteceklermiş",
                    createdAt: Date().addingTimeInterval(-5000),
                    likes: []
                ),
                ForumComment(
                    id: "c3",
                    postId: "1",
                    authorId: "user4",
                    authorName: "Can Öztürk",
                    content: "Kütüphanedeki wifi daha iyi çalışıyor",
                    createdAt: Date().addingTimeInterval(-4000),
                    likes: ["user1", "user2"]
                ),
                ForumComment(
                    id: "c4",
                    postId: "1",
                    authorId: "user5",
                    authorName: "Elif Yıldız",
                    content: "Modem'i resetleyin bazen işe yarıyor",
                    createdAt: Date().addingTimeInterval(-3000),
                    likes: []
                ),
                ForumComment(
                    id: "c5",
                    postId: "1",
                    authorId: "user6",
                    authorName: "Burak Şahin",
                    content: "5G'ye geçtim artık wifi kullanmıyorum 😅",
                    createdAt: Date().addingTimeInterval(-2000),
                    likes: ["user3"]
                ),
                ForumComment(
                    id: "c6",
                    postId: "2",
                    authorId: "user4",
                    authorName: "Selin Yılmaz",
                    content: "Benim notlarım var, DM atabilirsiniz",
                    createdAt: Date().addingTimeInterval(-3500),
                    likes: ["user1", "user2", "user3"]
                ),
                ForumComment(
                    id: "c7",
                    postId: "2",
                    authorId: "user5",
                    authorName: "Kaan Demir",
                    content: "YouTube'da çok iyi anlatım videoları var",
                    createdAt: Date().addingTimeInterval(-3200),
                    likes: ["user2"]
                ),
                ForumComment(
                    id: "c8",
                    postId: "2",
                    authorId: "user1",
                    authorName: "Deniz Acar",
                    content: "Grup çalışması yapmak isteyen var mı?",
                    createdAt: Date().addingTimeInterval(-2800),
                    likes: ["user3", "user4"]
                )
            ]
            saveComments()
        }
    }
    
    private func savePosts() {
        LocalStorageManager.shared.cacheForumPosts(posts)
    }
    
    private func saveComments() {
        LocalStorageManager.shared.cacheForumComments(comments)
    }
    
    // MARK: - Filtered Posts
    var filteredPosts: [ForumPost] {
        if let category = selectedCategory {
            return posts.filter { $0.category == category }.sorted { $0.createdAt > $1.createdAt }
        }
        return posts.sorted {
            if $0.isPinned != $1.isPinned {
                return $0.isPinned
            }
            return $0.createdAt > $1.createdAt
        }
    }
    
    // MARK: - Post Actions
    func createPost(authorId: String, authorName: String, category: ForumCategory, title: String, content: String, tags: [String]) {
        let newPost = ForumPost(
            id: UUID().uuidString,
            authorId: authorId,
            authorName: authorName,
            category: category,
            title: title,
            content: content,
            createdAt: Date(),
            likes: [],
            commentCount: 0,
            isPinned: false,
            tags: tags
        )
        
        posts.insert(newPost, at: 0)
        savePosts()
        Logger.info("Forum post created: \(title)")
    }
    
    func toggleLike(postId: String, userId: String) {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else { return }
        
        if posts[index].likes.contains(userId) {
            posts[index].likes.removeAll { $0 == userId }
        } else {
            posts[index].likes.append(userId)
        }
        savePosts()
    }
    
    func togglePin(postId: String) {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else { return }
        posts[index].isPinned.toggle()
        savePosts()
        Logger.info("Post \(posts[index].isPinned ? "pinned" : "unpinned"): \(posts[index].title)")
    }
    
    func deletePost(postId: String) {
        posts.removeAll { $0.id == postId }
        comments.removeAll { $0.postId == postId }
        savePosts()
        saveComments()
    }
    
    // MARK: - Comment Actions
    func addComment(postId: String, authorId: String, authorName: String, content: String) {
        let newComment = ForumComment(
            id: UUID().uuidString,
            postId: postId,
            authorId: authorId,
            authorName: authorName,
            content: content,
            createdAt: Date(),
            likes: []
        )
        
        comments.append(newComment)
        
        // Update comment count
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].commentCount += 1
            savePosts()
        }
        
        saveComments()
    }
    
    func getComments(for postId: String) -> [ForumComment] {
        return comments.filter { $0.postId == postId }.sorted { $0.createdAt < $1.createdAt }
    }
    
    func toggleCommentLike(commentId: String, userId: String) {
        guard let index = comments.firstIndex(where: { $0.id == commentId }) else { return }
        
        if comments[index].likes.contains(userId) {
            comments[index].likes.removeAll { $0 == userId }
        } else {
            comments[index].likes.append(userId)
        }
        saveComments()
    }
}

import SwiftUI
import Combine

// MARK: - ForumView
struct ForumView: View {
    @EnvironmentObject var forumViewModel: ForumViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingCreatePost = false
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        CategoryChip(
                            category: nil,
                            title: "Tümü",
                            isSelected: forumViewModel.selectedCategory == nil
                        ) {
                            forumViewModel.selectedCategory = nil
                        }
                        
                        ForEach(ForumCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                category: category,
                                title: category.rawValue,
                                isSelected: forumViewModel.selectedCategory == category
                            ) {
                                forumViewModel.selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Posts List
                List(forumViewModel.filteredPosts) { post in
                    NavigationLink(value: post) {
                        ForumPostRow(post: post)
                            .environmentObject(forumViewModel)
                            .environmentObject(authViewModel)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Forum")
            .navigationDestination(for: ForumPost.self) { post in
                ForumPostDetailView(post: post)
                    .environmentObject(forumViewModel)
                    .environmentObject(authViewModel)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreatePost = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingCreatePost) {
                CreateForumPostView()
                    .environmentObject(forumViewModel)
                    .environmentObject(authViewModel)
            }
            .onChange(of: forumViewModel.selectedCategory) { _, _ in
                navigationPath.removeLast(navigationPath.count)
            }
        }
    }
}

struct CategoryChip: View {
    let category: ForumCategory?
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// ✅ DÜZELTME: ForumPostRow - Beğeni butonu düzeltildi
struct ForumPostRow: View {
    let post: ForumPost
    @EnvironmentObject var forumViewModel: ForumViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if post.isPinned {
                    Image(systemName: "pin.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
                Text(post.category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                
                Spacer()
                
                Text(post.createdAt.timeAgoDisplay())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(post.title)
                .font(.headline)
                .lineLimit(2)
            
            Text(post.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(post.authorName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // ✅ DÜZELTME: Like butonu - NavigationLink dışında
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .gray)
                        Text("\(post.likes.count)")
                            .foregroundColor(isLiked ? .red : .gray)
                    }
                    .font(.caption)
                    .onTapGesture {
                        forumViewModel.toggleLike(postId: post.id, userId: authViewModel.currentUser?.id ?? "")
                    }
                    
                    Label("\(post.commentCount)", systemImage: "bubble.left.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if authViewModel.currentUser?.id == post.authorId || authViewModel.isAdmin {
                Button {
                    forumViewModel.togglePin(postId: post.id)
                } label: {
                    Label(post.isPinned ? "Sabitlemeyi Kaldır" : "Sabitle", systemImage: post.isPinned ? "pin.slash" : "pin")
                }
                .tint(post.isPinned ? .gray : .orange)
            }
        }
    }
    
    // ✅ Helper: Beğenme durumu
    private var isLiked: Bool {
        guard let userId = authViewModel.currentUser?.id else { return false }
        return post.likes.contains(userId)
    }
}

// MARK: - Forum Post Detail View
struct ForumPostDetailView: View {
    let post: ForumPost
    @EnvironmentObject var forumViewModel: ForumViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var commentText = ""
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Post Content
                    VStack(alignment: .leading, spacing: 12) {
                        Text(post.title)
                            .font(.title2)
                            .bold()
                        
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(post.authorName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(post.createdAt.timeAgoDisplay())
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Text(post.content)
                            .font(.body)
                        
                        // ✅ DÜZELTME: Like butonu - Çalışan versiyon
                        Button(action: {
                            forumViewModel.toggleLike(postId: post.id, userId: authViewModel.currentUser?.id ?? "")
                        }) {
                            HStack {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                Text("\(post.likes.count)")
                            }
                            .foregroundColor(isLiked ? .red : .gray)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    
                    Divider()
                    
                    // Comments
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Yorumlar (\(forumViewModel.getComments(for: post.id).count))")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(forumViewModel.getComments(for: post.id)) { comment in
                            CommentRow(comment: comment)
                                .environmentObject(forumViewModel)
                                .environmentObject(authViewModel)
                        }
                    }
                }
            }
            
            // Add Comment
            HStack {
                TextField("Yorum yaz...", text: $commentText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: addComment) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
                .disabled(commentText.isEmpty)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var isLiked: Bool {
        guard let userId = authViewModel.currentUser?.id else { return false }
        return post.likes.contains(userId)
    }
    
    private func addComment() {
        guard let user = authViewModel.currentUser, !commentText.isEmpty else { return }
        
        forumViewModel.addComment(
            postId: post.id,
            authorId: user.id,
            authorName: user.name,
            content: commentText
        )
        commentText = ""
    }
}

// ✅ DÜZELTME: CommentRow - Beğeni butonu çalışıyor
struct CommentRow: View {
    let comment: ForumComment
    @EnvironmentObject var forumViewModel: ForumViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {}) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(comment.authorName)
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text(comment.createdAt.timeAgoDisplay())
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            
            Text(comment.content)
                .font(.subheadline)
            
            // ✅ DÜZELTME: Yorum beğenisi - Çalışan versiyon
            Button(action: {
                forumViewModel.toggleCommentLike(commentId: comment.id, userId: authViewModel.currentUser?.id ?? "")
            }) {
                HStack(spacing: 4) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.caption)
                    Text("\(comment.likes.count)")
                        .font(.caption)
                }
                .foregroundColor(isLiked ? .red : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private var isLiked: Bool {
        guard let userId = authViewModel.currentUser?.id else { return false }
        return comment.likes.contains(userId)
    }
}

struct CreateForumPostView: View {
    @EnvironmentObject var forumViewModel: ForumViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCategory: ForumCategory = .general
    @State private var title = ""
    @State private var content = ""
    @State private var tags: [String] = []
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kategori")) {
                    Picker("Kategori", selection: $selectedCategory) {
                        ForEach(ForumCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section(header: Text("İçerik")) {
                    TextField("Başlık", text: $title)
                    TextEditor(text: $content)
                        .frame(height: 150)
                }
                
                Section {
                    PrimaryButton(
                        title: "Paylaş",
                        action: createPost,
                        isEnabled: !title.isEmpty && !content.isEmpty
                    )
                }
            }
            .navigationTitle("Yeni Gönderi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
            .alert("Bilgi", isPresented: $showAlert) {
                Button("Tamam") {
                    if alertMessage.contains("oluşturuldu") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func createPost() {
        guard let user = authViewModel.currentUser else {
            alertMessage = "Kullanıcı bilgisi bulunamadı"
            showAlert = true
            return
        }
        
        forumViewModel.createPost(
            authorId: user.id,
            authorName: user.name,
            category: selectedCategory,
            title: title,
            content: content,
            tags: tags
        )
        
        alertMessage = "Gönderi başarıyla oluşturuldu! 🎉"
        showAlert = true
        
        Logger.info("Forum post created: \(title)")
    }
}

import SwiftUI
import Combine

// MARK: - MessagesView (Conversation List)
struct MessagesView: View {
    @EnvironmentObject var messagingViewModel: MessagingViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var socialViewModel = SocialViewModel()  // ✅ EKLENDI
    @State private var showingNewMessage = false
    
    var body: some View {
        NavigationView {
            List(messagingViewModel.conversations) { conversation in
                NavigationLink(destination: ChatView(conversation: conversation)
                    .environmentObject(messagingViewModel)
                    .environmentObject(authViewModel)) {
                    ConversationRow(conversation: conversation)
                }
            }
            .navigationTitle("Mesajlar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewMessage = true }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingNewMessage) {
                NewMessageView()
                    .environmentObject(socialViewModel)
                    .environmentObject(messagingViewModel)
                    .environmentObject(authViewModel)
            }
            .overlay {
                if messagingViewModel.conversations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "message.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Henüz mesaj yok")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Button(action: { showingNewMessage = true }) {
                            Text("İlk Mesajı Gönder")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - New Message View
struct NewMessageView: View {
    @EnvironmentObject var socialViewModel: SocialViewModel
    @EnvironmentObject var messagingViewModel: MessagingViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredUsers) { user in
                    Button(action: {
                        startConversation(with: user)
                    }) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text(user.name)
                                    .font(.headline)
                                Text(user.department)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Kullanıcı ara...")
            .navigationTitle("Yeni Mesaj")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
        }
    }
    
    private var filteredUsers: [User] {
        let allUsers = socialViewModel.allUsers.filter { $0.id != authViewModel.currentUser?.id }
        
        if searchText.isEmpty {
            return allUsers
        }
        return allUsers.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private func startConversation(with user: User) {
        // ✅ DÜZELTME: Kullanılmayan değişkeni _ ile değiştir
        _ = messagingViewModel.getOrCreateConversation(with: user.id, userName: user.name)
        dismiss()
    }
}

// MARK: - Conversation Row
struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Image(systemName: conversation.type == .group ? "person.3.fill" : "person.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(displayName)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(conversation.lastMessageTime.timeAgoDisplay())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(conversation.lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var displayName: String {
        if conversation.type == .group {
            return conversation.groupName ?? "Grup"
        } else {
            return conversation.participantNames.values.first ?? "Kullanıcı"
        }
    }
}

// MARK: - Chat View (Message Thread)
struct ChatView: View {
    let conversation: Conversation
    @EnvironmentObject var messagingViewModel: MessagingViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var messageText = ""
    @State private var messages: [Message] = []
    
    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(
                                message: message,
                                isCurrentUser: message.senderId == authViewModel.currentUser?.id
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                    .onAppear {
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: messages.count) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                }
            }
            
            // Message Input
            HStack {
                TextField("Mesaj yaz...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
        }
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMessages()
            messagingViewModel.markAsRead(conversationId: conversation.id)
        }
    }
    
    private var displayName: String {
        if conversation.type == .group {
            return conversation.groupName ?? "Grup"
        } else {
            return conversation.participantNames.values.first ?? "Kullanıcı"
        }
    }
    
    private func loadMessages() {
        messages = messagingViewModel.getMessages(for: conversation.id)
    }
    
    private func sendMessage() {
        guard let user = authViewModel.currentUser, !messageText.isEmpty else { return }
        
        messagingViewModel.sendMessage(
            conversationId: conversation.id,
            senderId: user.id,
            senderName: user.name,
            content: messageText,
            type: .text
        )
        
        messageText = ""
        loadMessages()
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = messages.last {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(message.createdAt.timeAgoDisplay())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !isCurrentUser {
                Spacer(minLength: 50)
            }
        }
    }
}

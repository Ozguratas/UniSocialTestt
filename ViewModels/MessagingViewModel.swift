import Foundation
import SwiftUI
import Combine

class MessagingViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var messages: [Message] = []
    @Published var isLoading = false
    
    init() {
        loadConversations()
        loadMessages()
        loadSampleData()
    }
    
    private func loadConversations() {
        let cached = LocalStorageManager.shared.loadCachedConversations()
        if !cached.isEmpty {
            self.conversations = cached
        }
    }
    
    private func loadMessages() {
        let cached = LocalStorageManager.shared.loadCachedMessages()
        if !cached.isEmpty {
            self.messages = cached
        }
    }
    
    private func loadSampleData() {
        if conversations.isEmpty {
            conversations = [
                Conversation(
                    id: "conv1",
                    type: .direct,
                    participants: ["user1", "currentUser"],
                    participantNames: ["user1": "Ahmet Yılmaz"],
                    lastMessage: "Yarın saat kaçta kalkıyoruz?",
                    lastMessageTime: Date().addingTimeInterval(-3600),
                    unreadCount: 2,
                    groupName: nil,
                    groupImage: nil
                ),
                Conversation(
                    id: "conv2",
                    type: .direct,
                    participants: ["user2", "currentUser"],
                    participantNames: ["user2": "Ayşe Demir"],
                    lastMessage: "Teşekkürler, güzel bir yolculuktu!",
                    lastMessageTime: Date().addingTimeInterval(-7200),
                    unreadCount: 0,
                    groupName: nil,
                    groupImage: nil
                ),
                Conversation(
                    id: "conv3",
                    type: .group,
                    participants: ["user1", "user2", "user3", "currentUser"],
                    participantNames: [
                        "user1": "Ahmet Yılmaz",
                        "user2": "Ayşe Demir",
                        "user3": "Mehmet Kaya"
                    ],
                    lastMessage: "Yarın etkinliğe geliyor musunuz?",
                    lastMessageTime: Date().addingTimeInterval(-10800),
                    unreadCount: 5,
                    groupName: "İTÜ Kampüs Topluluğu",
                    groupImage: "person.3.fill"
                )
            ]
            saveConversations()
        }
        
        if messages.isEmpty {
            messages = [
                Message(
                    id: "msg1",
                    conversationId: "conv1",
                    senderId: "user1",
                    senderName: "Ahmet Yılmaz",
                    content: "Merhaba! Yarın güzergahında yer var mı?",
                    type: .text,
                    createdAt: Date().addingTimeInterval(-7200),
                    isRead: true,
                    imageUrl: nil,
                    relatedId: nil
                ),
                Message(
                    id: "msg2",
                    conversationId: "conv1",
                    senderId: "currentUser",
                    senderName: "Ben",
                    content: "Evet var! 2 koltuk boş.",
                    type: .text,
                    createdAt: Date().addingTimeInterval(-7000),
                    isRead: true,
                    imageUrl: nil,
                    relatedId: nil
                ),
                Message(
                    id: "msg3",
                    conversationId: "conv1",
                    senderId: "user1",
                    senderName: "Ahmet Yılmaz",
                    content: "Yarın saat kaçta kalkıyoruz?",
                    type: .text,
                    createdAt: Date().addingTimeInterval(-3600),
                    isRead: false,
                    imageUrl: nil,
                    relatedId: nil
                )
            ]
            saveMessages()
        }
    }
    
    private func saveConversations() {
        LocalStorageManager.shared.cacheConversations(conversations)
    }
    
    private func saveMessages() {
        LocalStorageManager.shared.cacheMessages(messages)
    }
    
    // MARK: - Conversation Actions
    func createConversation(with userId: String, userName: String) -> Conversation {
        let newConversation = Conversation(
            id: UUID().uuidString,
            type: .direct,
            participants: [userId, "currentUser"],
            participantNames: [userId: userName],
            lastMessage: "",
            lastMessageTime: Date(),
            unreadCount: 0,
            groupName: nil,
            groupImage: nil
        )
        
        conversations.insert(newConversation, at: 0)
        saveConversations()
        
        return newConversation
    }
    
    func getOrCreateConversation(with userId: String, userName: String) -> Conversation {
        if let existing = conversations.first(where: {
            $0.participants.contains(userId) && $0.type == .direct
        }) {
            return existing
        }
        return createConversation(with: userId, userName: userName)
    }
    
    // MARK: - Message Actions
    func sendMessage(conversationId: String, senderId: String, senderName: String, content: String, type: MessageType = .text) {
        let newMessage = Message(
            id: UUID().uuidString,
            conversationId: conversationId,
            senderId: senderId,
            senderName: senderName,
            content: content,
            type: type,
            createdAt: Date(),
            isRead: false,
            imageUrl: nil,
            relatedId: nil
        )
        
        messages.append(newMessage)
        
        // Update conversation
        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[index].lastMessage = content
            conversations[index].lastMessageTime = Date()
            saveConversations()
        }
        
        saveMessages()
        Logger.info("Message sent to conversation: \(conversationId)")
    }
    
    func getMessages(for conversationId: String) -> [Message] {
        return messages.filter { $0.conversationId == conversationId }.sorted { $0.createdAt < $1.createdAt }
    }
    
    func markAsRead(conversationId: String) {
        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[index].unreadCount = 0
            saveConversations()
        }
        
        for i in messages.indices where messages[i].conversationId == conversationId {
            messages[i].isRead = true
        }
        saveMessages()
    }
    
    var totalUnreadCount: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }
}

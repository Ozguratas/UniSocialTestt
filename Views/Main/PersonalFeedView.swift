import SwiftUI

struct PersonalFeedView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var feedViewModel: FeedViewModel
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var routeViewModel: RouteViewModel
    @StateObject private var socialViewModel = SocialViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 1. GÜNÜN SELAMLAMASİ + HIZLI AKSİYONLAR
                personalHeaderSection
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                Divider()
                    .padding(.vertical, 8)
                
                // 2. HİKAYELER (Sadece arkadaşlarınkiler)
                if !friendStories.isEmpty {
                    friendStoriesSection
                        .padding(.vertical, 12)
                }
                
                // 3. BUGÜN NE YAPSAN?
                suggestionsForTodaySection
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                
                // 4. YAKIN PLANLARIM
                myUpcomingPlansSection
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                
                // 5. ARKADAŞLARIMIN AKTİVİTELERİ
                friendsActivitySection
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                
                // 6. BİLDİRİMLER & ETKİLEŞİMLER
                interactionsSection
                    .padding(.horizontal)
                    .padding(.bottom, 16)
            }
        }
        .navigationTitle(greeting)
        .refreshable {
            feedViewModel.refreshFeed()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                notificationButton
            }
        }
    }
    
    // MARK: - KİŞİSEL HEADER
    private var personalHeaderSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Profil resmi
                NavigationLink(destination: ProfileView()
                    .environmentObject(authViewModel)) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                }
                
                // Kullanıcı bilgileri
                VStack(alignment: .leading, spacing: 4) {
                    Text("Merhaba, \(authViewModel.currentUser?.name.components(separatedBy: " ").first ?? "")! 👋")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                            Text("\(friendCount) arkadaş")
                                .font(.caption)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", authViewModel.currentUser?.rating ?? 0))
                                .font(.caption)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("\(authViewModel.currentUser?.level ?? 1). seviye")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Hızlı Aksiyonlar
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Paylaş",
                    color: .blue
                ) {
                    // TODO: Yeni gönderi
                }
                
                QuickActionButton(
                    icon: "calendar.badge.plus",
                    title: "Etkinlik",
                    color: .orange
                ) {
                    // TODO: Yeni etkinlik
                }
                
                QuickActionButton(
                    icon: "person.badge.plus",
                    title: "Arkadaş",
                    color: .purple
                ) {
                    // TODO: Arkadaş ekle
                }
            }
        }
    }
    
    // MARK: - ARKADAŞ HİKAYELERİ
    private var friendStoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hikayeler")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Kendi hikayeni ekle butonu
                    AddStoryButton()
                    
                    // Arkadaş hikayeleri
                    ForEach(friendStories) { story in
                        StoryCircle(story: story)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - BUGÜN NE YAPSAN?
    private var suggestionsForTodaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text("Bugün Ne Yapsan?")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                // Yakındaki arkadaşlar
                if let nearbyFriend = nearbyFriends.first {
                    SuggestionCard(
                        icon: "person.wave.2.fill",
                        title: "\(nearbyFriend.name) yakınında",
                        subtitle: "Kahve içmeye ne dersin?",
                        color: .purple,
                        action: "Mesaj At"
                    ) {
                        // TODO: Mesaj gönder
                    }
                }
                
                // Bugünkü etkinlikler
                if let todayEvent = todayEvents.first {
                    SuggestionCard(
                        icon: "calendar",
                        title: todayEvent.title,
                        subtitle: "Bugün \(todayEvent.eventTime.formatted(date: .omitted, time: .shortened))",
                        color: .orange,
                        action: "Katıl"
                    ) {
                        // TODO: Etkinliğe katıl
                    }
                }
                
                // Ortak ilgi alanları
                if let commonInterestFriend = friendsWithCommonInterests.first {
                    SuggestionCard(
                        icon: "heart.circle.fill",
                        title: "\(commonInterestFriend.name) ile ortak ilginiz: \(commonInterest)",
                        subtitle: "Tanışmak ister misiniz?",
                        color: .pink,
                        action: "Mesaj At"
                    ) {
                        // TODO: Mesaj gönder
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - YAKIN PLANLARIM
    private var myUpcomingPlansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.blue)
                Text("Yaklaşan Planlarım")
                    .font(.headline)
                Spacer()
                if !myUpcomingPlans.isEmpty {
                    Text("\(myUpcomingPlans.count)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }
            
            if myUpcomingPlans.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Henüz planın yok")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("Etkinlik Bul") {
                            // TODO: Etkinlikler tab'ına git
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(myUpcomingPlans) { event in
                        MyPlanCard(event: event)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - ARKADAŞLARIMIN AKTİVİTELERİ
    private var friendsActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.circle.fill")
                    .foregroundColor(.green)
                Text("Arkadaşlarımın Aktiviteleri")
                    .font(.headline)
                Spacer()
            }
            
            if friendActivities.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "person.2")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Henüz aktivite yok")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    ForEach(friendActivities) { activity in
                        FriendActivityCard(activity: activity)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - ETKİLEŞİMLER
    private var interactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(.red)
                Text("Etkileşimler")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                InteractionRow(
                    icon: "heart.fill",
                    text: "Zeynep senin gönderini beğendi",
                    time: "5 dk önce",
                    color: .red
                )
                
                InteractionRow(
                    icon: "bubble.left.fill",
                    text: "Ahmet gönderine yorum yaptı",
                    time: "1 saat önce",
                    color: .blue
                )
                
                InteractionRow(
                    icon: "person.badge.plus.fill",
                    text: "Mehmet arkadaş isteği gönderdi",
                    time: "2 saat önce",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - BİLDİRİM BUTONU
    private var notificationButton: some View {
        Button(action: {}) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .foregroundColor(.blue)
                
                if hasUnreadNotifications {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(x: 4, y: -4)
                }
            }
        }
    }
    
    // MARK: - COMPUTED PROPERTIES
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Günaydın"
        case 12..<17: return "İyi Günler"
        case 17..<21: return "İyi Akşamlar"
        default: return "İyi Geceler"
        }
    }
    
    private var friendCount: Int {
        authViewModel.currentUser?.friends.count ?? 0
    }
    
    private var friendStories: [Story] {
        guard let currentUser = authViewModel.currentUser else { return [] }
        return feedViewModel.stories.filter { story in
            currentUser.friends.contains(story.userId)
        }
    }
    
    private var todayEvents: [Event] {
        guard let userId = authViewModel.currentUser?.id else { return [] }
        return eventViewModel.events.filter { event in
            Calendar.current.isDateInToday(event.eventTime) &&
            event.participants.contains(userId)
        }
    }
    
    private var myUpcomingPlans: [Event] {
        guard let userId = authViewModel.currentUser?.id else { return [] }
        return eventViewModel.events.filter { event in
            event.participants.contains(userId) &&
            event.eventTime > Date()
        }.sorted { $0.eventTime < $1.eventTime }
    }
    
    private var nearbyFriends: [User] {
        guard let currentUser = authViewModel.currentUser else { return [] }
        return socialViewModel.allUsers.filter { user in
            currentUser.friends.contains(user.id)
        }.prefix(3).map { $0 }
    }
    
    private var friendsWithCommonInterests: [User] {
        guard let currentUser = authViewModel.currentUser else { return [] }
        return socialViewModel.allUsers.filter { user in
            currentUser.friends.contains(user.id) &&
            !Set(user.interests).intersection(Set(currentUser.interests)).isEmpty
        }
    }
    
    private var commonInterest: String {
        guard let currentUser = authViewModel.currentUser,
              let friend = friendsWithCommonInterests.first else { return "" }
        return Set(friend.interests).intersection(Set(currentUser.interests)).first ?? ""
    }
    
    private var friendActivities: [FriendActivity] {
        // TODO: Mock data for now
        return []
    }
    
    private var hasUnreadNotifications: Bool {
        true // TODO: Gerçek bildirim sistemi
    }
}

// MARK: - YARDIMCI VIEW'LAR

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct AddStoryButton: View {
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 70, height: 70)
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
            }
            
            Text("Ekle")
                .font(.caption2)
                .foregroundColor(.blue)
        }
    }
}

struct SuggestionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: String
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: onTap) {
                Text(action)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(color.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MyPlanCard: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Text(event.eventTime.formatted(.dateTime.day()))
                    .font(.title3)
                    .fontWeight(.bold)
                Text(event.eventTime.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            .padding(.vertical, 8)
            .background(event.category.color.opacity(0.1))
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(event.eventTime.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "mappin")
                        .font(.caption2)
                    Text(event.location)
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FriendActivity: Identifiable {
    let id = UUID()
    let friendName: String
    let activityType: String
    let activityTitle: String
    let time: Date
    let icon: String
    let color: Color
}

struct FriendActivityCard: View {
    let activity: FriendActivity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .foregroundColor(activity.color)
                .frame(width: 40, height: 40)
                .background(activity.color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.friendName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(activity.activityTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(activity.time.timeAgoDisplay())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InteractionRow: View {
    let icon: String
    let text: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.subheadline)
                Text(time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - StoryCircle Component (PersonalFeedView.swift dosyasının EN ALTINA ekle)

struct StoryCircle: View {
    let story: Story
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.purple, .pink, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 70, height: 70)
                
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
            }
            
            Text(story.userName)
                .font(.caption2)
                .lineLimit(1)
                .frame(width: 70)
        }
    }
}

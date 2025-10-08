import SwiftUI

struct ImprovedDiscoverView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var socialViewModel = SocialViewModel()
    @StateObject private var eventViewModel = EventViewModel()
    @StateObject private var forumViewModel = ForumViewModel()
    @State private var selectedTab: DiscoverTab = .overview
    
    enum DiscoverTab: String, CaseIterable {
        case overview = "Genel"
        case people = "İnsanlar"
        case groups = "Gruplar"
        case places = "Mekanlar"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Seçici
            discoverTabPicker
            
            ScrollView {
                VStack(spacing: 20) {
                    switch selectedTab {
                    case .overview:
                        overviewContent
                    case .people:
                        peopleContent
                    case .groups:
                        groupsContent
                    case .places:
                        placesContent
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Keşfet")
    }
    
    // MARK: - Tab Picker
    private var discoverTabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(DiscoverTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedTab == tab ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedTab == tab ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - GENEL BAKIŞ (En önemli kısım)
    private var overviewContent: some View {
        VStack(spacing: 20) {
            // 1. KAMPÜS İSTATİSTİKLERİ
            campusStatsCard
            
            // 2. ŞU ANDA AKTİF
            activeNowSection
            
            // 3. BUGÜN NEREDE TOPLANIYORUZ
            popularPlacesTodaySection
            
            // 4. TREND KONULAR
            trendingTopicsSection
            
            // 5. YENİ ARKADAŞLAR
            quickPeopleSuggestions
        }
    }
    
    // MARK: - İSTATİSTİKLER KARTI
    private var campusStatsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Kampüs Nabzı")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 0) {
                StatBox(
                    icon: "person.3.fill",
                    value: "\(socialViewModel.allUsers.count)",
                    label: "Aktif Kullanıcı",
                    color: .blue
                )
                
                Divider()
                
                StatBox(
                    icon: "calendar",
                    value: "\(todayEventsCount)",
                    label: "Bugünkü Etkinlik",
                    color: .orange
                )
                
                Divider()
                
                StatBox(
                    icon: "bubble.left.fill",
                    value: "\(forumViewModel.posts.count)",
                    label: "Forum Konusu",
                    color: .purple
                )
            }
            .frame(height: 80)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - ŞU ANDA AKTİF
    private var activeNowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
                Text("Şu Anda Aktif")
                    .font(.headline)
                Spacer()
            }
            
            if activeEvents.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "moon.stars.fill")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Şu anda aktif etkinlik yok")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(activeEvents) { event in
                            ActiveEventCard(event: event)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - POPÜLER MEKANLAR
    private var popularPlacesTodaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                Text("Popüler Mekanlar")
                    .font(.headline)
                Spacer()
                Button("Haritada Gör") {
                    // TODO: Harita görünümü
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                PopularPlaceRow(
                    name: "Kampüs Kütüphanesi",
                    icon: "book.fill",
                    userCount: 45,
                    color: .blue
                )
                PopularPlaceRow(
                    name: "Kafeterya",
                    icon: "cup.and.saucer.fill",
                    userCount: 32,
                    color: .orange
                )
                PopularPlaceRow(
                    name: "Spor Salonu",
                    icon: "figure.run",
                    userCount: 18,
                    color: .green
                )
            }
        }
    }
    
    // MARK: - TREND KONULAR
    private var trendingTopicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("Trend Konular")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: ForumView()
                    .environmentObject(forumViewModel)
                    .environmentObject(authViewModel)) {
                    Text("Foruma Git")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            VStack(spacing: 8) {
                ForEach(forumViewModel.posts.prefix(3)) { post in
                    TrendingTopicRow(post: post)
                }
            }
        }
    }
    
    // MARK: - HIZLI ARKADAŞ ÖNERİLERİ
    private var quickPeopleSuggestions: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.purple)
                Text("Tanışabileceğin İnsanlar")
                    .font(.headline)
                Spacer()
                Button("Tümü") {
                    selectedTab = .people
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if let currentUser = authViewModel.currentUser {
                let recommended = socialViewModel.getRecommendedUsers(
                    currentUserId: currentUser.id,
                    currentUserInterests: currentUser.interests,
                    currentUserFriends: currentUser.friends
                )
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recommended.prefix(5)) { user in
                            QuickUserCard(user: user)
                                .environmentObject(socialViewModel)
                                .environmentObject(authViewModel)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - İNSANLAR TAB
    private var peopleContent: some View {
        VStack(spacing: 16) {
            // Arama
            SearchBar(text: $socialViewModel.searchText)
            
            // İlgi alanı filtreleri
            InterestFilterSection(selectedInterests: $socialViewModel.selectedInterests)
            
            // Kullanıcı listesi
            if let currentUser = authViewModel.currentUser {
                let users = socialViewModel.getDiscoverUsers(
                    currentUserId: currentUser.id,
                    currentUserFriends: currentUser.friends
                )
                
                ForEach(users) { user in
                    UserCard(user: user)
                        .environmentObject(socialViewModel)
                        .environmentObject(authViewModel)
                }
            }
        }
    }
    
    // MARK: - GRUPLAR TAB
    private var groupsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("İlgi Alanı Grupları")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                GroupCard(
                    name: "Müzik Sevenler",
                    icon: "music.note",
                    memberCount: 45,
                    color: .purple,
                    description: "Kampüste müzik dinleyip paylaşanlar"
                )
                
                GroupCard(
                    name: "Spor Ekibi",
                    icon: "figure.run",
                    memberCount: 32,
                    color: .green,
                    description: "Birlikte spor yapan arkadaşlar"
                )
                
                GroupCard(
                    name: "Yazılımcılar",
                    icon: "chevron.left.forwardslash.chevron.right",
                    memberCount: 67,
                    color: .blue,
                    description: "Kod yazan, teknoloji konuşan grup"
                )
                
                GroupCard(
                    name: "Fotoğraf Tutkunları",
                    icon: "camera.fill",
                    memberCount: 28,
                    color: .orange,
                    description: "Kampüsün en güzel karelerini yakalayalım"
                )
                
                GroupCard(
                    name: "Kitap Kulübü",
                    icon: "book.fill",
                    memberCount: 41,
                    color: .brown,
                    description: "Kitap okuyup tartışan topluluk"
                )
            }
        }
    }
    
    // MARK: - MEKANLAR TAB
    private var placesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Kampüs Mekanları")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                PlaceCard(
                    name: "Kampüs Kütüphanesi",
                    icon: "book.fill",
                    activeUsers: 45,
                    rating: 4.8,
                    color: .blue,
                    tags: ["Sessiz", "WiFi", "Çalışma Alanı"]
                )
                
                PlaceCard(
                    name: "Kafeterya",
                    icon: "cup.and.saucer.fill",
                    activeUsers: 32,
                    rating: 4.5,
                    color: .orange,
                    tags: ["Yemek", "Sosyal", "Uygun Fiyat"]
                )
                
                PlaceCard(
                    name: "Spor Salonu",
                    icon: "figure.run",
                    activeUsers: 18,
                    rating: 4.7,
                    color: .green,
                    tags: ["Fitness", "Basketbol", "Tenis"]
                )
                
                PlaceCard(
                    name: "Öğrenci Kulübü",
                    icon: "person.3.fill",
                    activeUsers: 25,
                    rating: 4.9,
                    color: .purple,
                    tags: ["Etkinlik", "Toplantı", "Sosyal"]
                )
                
                PlaceCard(
                    name: "Yeşil Alan",
                    icon: "leaf.fill",
                    activeUsers: 12,
                    rating: 4.6,
                    color: .green,
                    tags: ["Doğa", "Dinlenme", "Piknik"]
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    private var todayEventsCount: Int {
        eventViewModel.events.filter { event in
            Calendar.current.isDateInToday(event.eventTime)
        }.count
    }
    
    private var activeEvents: [Event] {
        eventViewModel.events.filter { event in
            let now = Date()
            let eventStart = event.eventTime
            let eventEnd = eventStart.addingTimeInterval(7200) // 2 saat varsayım
            return now >= eventStart && now <= eventEnd
        }
    }
}

// MARK: - YARDIMCI VIEW'LAR

struct StatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ActiveEventCard: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: event.category.icon)
                    .foregroundColor(event.category.color)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("CANLI")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            
            Text(event.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
            
            Text(event.location)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.caption2)
                Text("\(event.participants.count) kişi")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 180)
        .background(
            LinearGradient(
                colors: [event.category.color.opacity(0.1), event.category.color.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(event.category.color.opacity(0.3), lineWidth: 2)
        )
    }
}

struct PopularPlaceRow: View {
    let name: String
    let icon: String
    let userCount: Int
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                    Text("\(userCount) kişi burada")
                        .font(.caption)
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

struct TrendingTopicRow: View {
    let post: ForumPost
    
    var body: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(post.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(post.category.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.fill")
                            .font(.caption2)
                        Text("\(post.commentCount)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct QuickUserCard: View {
    let user: User
    @EnvironmentObject var socialViewModel: SocialViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text(user.name)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            Text(user.department)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Button(action: {
                if let currentUserId = authViewModel.currentUser?.id {
                    socialViewModel.sendFriendRequest(from: currentUserId, to: user.id)
                }
            }) {
                Image(systemName: "person.badge.plus")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .frame(width: 100)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Ara...", text: $text)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InterestFilterSection: View {
    @Binding var selectedInterests: Set<String>
    let interests = ["Müzik", "Spor", "Teknoloji", "Sanat", "Seyahat", "Yemek"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(interests, id: \.self) { interest in
                    Button(action: {
                        if selectedInterests.contains(interest) {
                            selectedInterests.remove(interest)
                        } else {
                            selectedInterests.insert(interest)
                        }
                    }) {
                        Text(interest)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedInterests.contains(interest) ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedInterests.contains(interest) ? .white : .primary)
                            .cornerRadius(16)
                    }
                }
            }
        }
    }
}

struct GroupCard: View {
    let name: String
    let icon: String
    let memberCount: Int
    let color: Color
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(color.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                    Text("\(memberCount) üye")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Text("Katıl")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(color)
                    .cornerRadius(20)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct PlaceCard: View {
    let name: String
    let icon: String
    let activeUsers: Int
    let rating: Double
    let color: Color
    let tags: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 50, height: 50)
                    .background(color.opacity(0.1))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption2)
                            Text("\(activeUsers) kişi")
                                .font(.caption)
                        }
                        
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(color)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(color.opacity(0.1))
                            .foregroundColor(color)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

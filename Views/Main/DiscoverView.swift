import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var socialViewModel = SocialViewModel()
    @State private var searchText = ""
    @State private var selectedFilter: UserFilter = .all
    
    var body: some View {
        VStack {
            // Filter Tabs
            filterTabs
            
            // Search Bar
            searchBar
            
            // Users List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredUsers) { user in
                        UserCard(user: user)
                            .environmentObject(socialViewModel)
                            .environmentObject(authViewModel)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Keşfet")
        .onAppear {
            socialViewModel.loadUsers()
        }
    }
    
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(UserFilter.allCases, id: \.self) { filter in
                    FilterTab(
                        title: filter.title,
                        icon: filter.icon,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("İsim, bölüm veya ilgi alanı ara...", text: $searchText)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var filteredUsers: [User] {
        var users = socialViewModel.allUsers.filter { $0.id != authViewModel.currentUser?.id }
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .students:
            users = users.filter { !$0.isDriver }
        case .drivers:
            users = users.filter { $0.isDriver }
        case .verified:
            users = users.filter { $0.isVerified }
        case .nearby:
            // TODO: Implement location-based filtering
            break
        }
        
        // Apply search
        if !searchText.isEmpty {
            users = users.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.department.localizedCaseInsensitiveContains(searchText) ||
                $0.interests.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return users
    }
}

enum UserFilter: CaseIterable {
    case all, students, drivers, verified, nearby
    
    var title: String {
        switch self {
        case .all: return "Tümü"
        case .students: return "Öğrenciler"
        case .drivers: return "Sürücüler"
        case .verified: return "Doğrulanmış"
        case .nearby: return "Yakınımda"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "person.2.fill"
        case .students: return "book.fill"
        case .drivers: return "car.fill"
        case .verified: return "checkmark.seal.fill"
        case .nearby: return "location.fill"
        }
    }
}

struct FilterTab: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct UserCard: View {
    let user: User
    @EnvironmentObject var socialViewModel: SocialViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showProfile = false
    
    var body: some View {
        Button(action: { showProfile = true }) {
            HStack(spacing: 16) {
                // Avatar
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                }
                
                // User Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(user.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(user.department)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", user.rating))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if user.isDriver {
                            Text("•")
                                .foregroundColor(.secondary)
                            Image(systemName: "car.fill")
                                .font(.caption)
                            Text("Sürücü")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Interests
                    if !user.interests.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(user.interests.prefix(3), id: \.self) { interest in
                                    Text(interest)
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Action Button
                if let currentUserId = authViewModel.currentUser?.id {
                    if user.friends.contains(currentUserId) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    } else {
                        Button(action: {
                            socialViewModel.sendFriendRequest(from: currentUserId, to: user.id)
                        }) {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .sheet(isPresented: $showProfile) {
            UserProfileView(user: user)
                .environmentObject(authViewModel)
                .environmentObject(socialViewModel)
        }
    }
}

struct UserProfileView: View {
    let user: User
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var socialViewModel: SocialViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 100))
                                .foregroundColor(.blue)
                            
                            if user.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.title)
                                    .foregroundColor(.green)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                        }
                        
                        Text(user.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(user.department)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            VStack {
                                Text("\(user.totalRides)")
                                    .font(.headline)
                                Text("Yolculuk")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text(String(format: "%.1f", user.rating))
                                    .font(.headline)
                                Text("Puan")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(user.friends.count)")
                                    .font(.headline)
                                Text("Arkadaş")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    
                    // Bio
                    if !user.bio.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hakkında")
                                .font(.headline)
                            Text(user.bio)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Interests
                    if !user.interests.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("İlgi Alanları")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(user.interests, id: \.self) { interest in
                                    Text(interest)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Action Buttons
                    if let currentUserId = authViewModel.currentUser?.id, currentUserId != user.id {
                        VStack(spacing: 12) {
                            if user.friends.contains(currentUserId) {
                                Button(action: {}) {
                                    HStack {
                                        Image(systemName: "message.fill")
                                        Text("Mesaj Gönder")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            } else {
                                Button(action: {
                                    socialViewModel.sendFriendRequest(from: currentUserId, to: user.id)
                                    dismiss()
                                }) {
                                    HStack {
                                        Image(systemName: "person.badge.plus")
                                        Text("Arkadaş Ekle")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

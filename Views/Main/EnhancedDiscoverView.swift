import SwiftUI

struct EnhancedDiscoverView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var socialViewModel = SocialViewModel()
    @State private var searchText = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Arama çubuğu
                searchBar
                
                // Yeni Üyeler
                newMembersSection
                
                // Senin Gibi İnsanlar
                recommendedUsersSection
                
                // Tüm Kullanıcılar
                allUsersSection
            }
            .padding()
        }
        .navigationTitle("Keşfet")
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("İsim, bölüm ara...", text: $searchText)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var newMembersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text("Yeni Katılanlar")
                    .font(.headline)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(socialViewModel.allUsers.prefix(5)) { user in
                        NewMemberCard(user: user)
                            .environmentObject(socialViewModel)
                            .environmentObject(authViewModel)
                    }
                }
            }
        }
    }
    
    private var recommendedUsersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.purple)
                Text("Senin Gibi İnsanlar")
                    .font(.headline)
                
                Spacer()
            }
            
            if let currentUser = authViewModel.currentUser {
                let recommended = socialViewModel.getRecommendedUsers(
                    currentUserId: currentUser.id,
                    currentUserInterests: currentUser.interests,
                    currentUserFriends: currentUser.friends
                )
                
                ForEach(recommended.prefix(5)) { user in
                    UserCard(user: user)
                        .environmentObject(socialViewModel)
                        .environmentObject(authViewModel)
                }
            }
        }
    }
    
    private var allUsersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.blue)
                Text("Tüm Kullanıcılar")
                    .font(.headline)
                
                Spacer()
            }
            
            if let currentUser = authViewModel.currentUser {
                let allUsers = socialViewModel.getDiscoverUsers(
                    currentUserId: currentUser.id,
                    currentUserFriends: currentUser.friends
                )
                
                ForEach(allUsers) { user in
                    UserCard(user: user)
                        .environmentObject(socialViewModel)
                        .environmentObject(authViewModel)
                }
            }
        }
    }
}

struct NewMemberCard: View {
    let user: User
    @EnvironmentObject var socialViewModel: SocialViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text(user.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            Text(user.department)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Button(action: {
                if let currentUserId = authViewModel.currentUser?.id {
                    socialViewModel.sendFriendRequest(from: currentUserId, to: user.id)
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "person.badge.plus")
                    Text("Ekle")
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .frame(width: 140)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

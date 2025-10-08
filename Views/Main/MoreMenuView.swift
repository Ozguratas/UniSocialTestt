import SwiftUI

struct MoreMenuView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var routeViewModel: RouteViewModel
    @EnvironmentObject var messagingViewModel: MessagingViewModel
    @State private var showProfile = false
    @State private var showMessages = false
    
    var body: some View {
        List {
            // Profil Kartı
            profileSection
            
            // Ulaşım (Güzergahlar burada)
            transportSection
            
            // Sosyal
            socialSection
            
            // Güvenlik
            safetySection
            
            // Ayarlar
            settingsSection
            
            // Çıkış
            logoutSection
        }
        .navigationTitle("Diğer")
        .sheet(isPresented: $showProfile) {
            NavigationView {
                ProfileView()
                    .environmentObject(authViewModel)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Kapat") { showProfile = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showMessages) {
            NavigationView {
                MessagesView()
                    .environmentObject(messagingViewModel)
                    .environmentObject(authViewModel)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Kapat") { showMessages = false }
                        }
                    }
            }
        }
    }
    
    private var profileSection: some View {
        Section {
            Button(action: { showProfile = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(authViewModel.currentUser?.name ?? "Kullanıcı")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Profili Görüntüle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", authViewModel.currentUser?.rating ?? 0))
                                    .font(.caption)
                            }
                            
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "person.2.fill")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                Text("\(authViewModel.currentUser?.friends.count ?? 0) arkadaş")
                                    .font(.caption)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    private var transportSection: some View {
        Section("🚗 Ulaşım & Yolculuk") {
            NavigationLink(destination: HomeView()
                .environmentObject(routeViewModel)
                .environmentObject(authViewModel)) {
                HStack {
                    Image(systemName: "car.fill")
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    Text("Birlikte Gidelim")
                }
            }
            
            NavigationLink(destination: Text("Yolculuk Geçmişi")) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.orange)
                        .frame(width: 30)
                    Text("Yolculuk Geçmişi")
                }
            }
            
            NavigationLink(destination: Text("Kaydedilen Rotalar")) {
                HStack {
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(.purple)
                        .frame(width: 30)
                    Text("Kaydedilen Rotalar")
                }
            }
        }
    }
    
    private var socialSection: some View {
        Section("👥 Sosyal") {
            Button(action: { showMessages = true }) {
                HStack {
                    Image(systemName: "message.fill")
                        .foregroundColor(.green)
                        .frame(width: 30)
                    Text("Mesajlar")
                    Spacer()
                    if messagingViewModel.totalUnreadCount > 0 {
                        Text("\(messagingViewModel.totalUnreadCount)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            NavigationLink(destination: AchievementView()
                .environmentObject(authViewModel)) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                        .frame(width: 30)
                    Text("Başarımlar")
                }
            }
            
            NavigationLink(destination: Text("Gruplar")) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.purple)
                        .frame(width: 30)
                    Text("Gruplar")
                }
            }
        }
    }
    
    private var safetySection: some View {
        Section("🛡️ Güvenlik") {
            NavigationLink(destination: SafetySettingsView()
                .environmentObject(authViewModel)) {
                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.green)
                        .frame(width: 30)
                    Text("Güvenlik Ayarları")
                }
            }
            
            NavigationLink(destination: TrustedContactsView()) {
                HStack {
                    Image(systemName: "person.2.circle.fill")
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    Text("Acil Kişilerim")
                }
            }
        }
    }
    
    private var settingsSection: some View {
        Section("⚙️ Ayarlar") {
            NavigationLink(destination: Text("Bildirimler")) {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.red)
                        .frame(width: 30)
                    Text("Bildirimler")
                }
            }
            
            NavigationLink(destination: Text("Gizlilik")) {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                        .frame(width: 30)
                    Text("Gizlilik")
                }
            }
            
            NavigationLink(destination: Text("Yardım & Destek")) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    Text("Yardım & Destek")
                }
            }
            
            if authViewModel.isAdmin {
                NavigationLink(destination: AdminPanelView()
                    .environmentObject(authViewModel)) {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.orange)
                            .frame(width: 30)
                        Text("Yönetici Paneli")
                    }
                }
            }
        }
    }
    
    private var logoutSection: some View {
        Section {
            Button(action: { authViewModel.signOut() }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                        .frame(width: 30)
                    Text("Çıkış Yap")
                        .foregroundColor(.red)
                }
            }
        }
    }
}

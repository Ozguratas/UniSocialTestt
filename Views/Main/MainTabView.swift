import SwiftUI
import CoreLocation

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var routeViewModel = RouteViewModel()
    @StateObject private var eventViewModel = EventViewModel()
    @StateObject private var forumViewModel = ForumViewModel()
    @StateObject private var feedViewModel = FeedViewModel()
    @StateObject private var messagingViewModel = MessagingViewModel()
    
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var emergencyManager = EmergencyManager.shared
    @StateObject private var safetyManager = SafetyManager.shared
    
    @State private var selectedTab = 0
    @State private var hasActiveRide = false
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // 1. Ana Sayfa (Feed) - Sosyal odaklı
                NavigationStack {
                    PersonalFeedView()  // ← EnhancedFeedView yerine
                        .environmentObject(feedViewModel)
                        .environmentObject(eventViewModel)
                        .environmentObject(routeViewModel)
                        .environmentObject(authViewModel)
                }
                .tabItem {
                    Label("Ana Sayfa", systemImage: "house.fill")
                }
                .tag(0)
                
                // 2. Keşfet (İnsanlar) - ÖNE ÇIKTI ⭐
                NavigationStack {
                    ImprovedDiscoverView()
                        .environmentObject(authViewModel)
                }
                .tabItem {
                    Label("Keşfet", systemImage: "person.2.fill")
                }
                .tag(1)
                
                // 3. Etkinlikler - Sosyal aktiviteler ⭐
                NavigationStack {
                    EnhancedEventsView()
                        .environmentObject(eventViewModel)
                        .environmentObject(authViewModel)
                }
                .tabItem {
                    Label("Etkinlikler", systemImage: "calendar")
                }
                .tag(2)
                
                // 4. Forum
                NavigationStack {
                    ForumView()
                        .environmentObject(forumViewModel)
                        .environmentObject(authViewModel)
                }
                .tabItem {
                    Label("Forum", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(3)
                
                // 5. Diğer (Güzergahlar burada gizli)
                NavigationStack {
                    MoreMenuView()
                        .environmentObject(authViewModel)
                        .environmentObject(routeViewModel)
                        .environmentObject(messagingViewModel)
                }
                .tabItem {
                    Label("Diğer", systemImage: "ellipsis.circle")
                }
                .tag(4)
            }
            .accentColor(.blue)
            
            // SOS butonu sadece aktif yolculukta
            if hasActiveRide && !emergencyManager.isEmergencyActive {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        EmergencyButton()
                            .padding(.trailing, 20)
                            .padding(.bottom, 80)
                    }
                }
            }
            
            // Acil durum banner'ı
            if emergencyManager.isEmergencyActive {
                VStack {
                    emergencyBanner
                    Spacer()
                }
            }
        }
        .onAppear {
            requestLocationPermissionIfNeeded()
            checkEmergencyContactsSetup()
        }
        .onReceive(safetyManager.$activeSafetyCheck) { check in
            hasActiveRide = (check != nil)
        }
    }
    
    private var emergencyBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("ACİL DURUM AKTİF")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Güvenilir kişileriniz bilgilendirildi")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            Button(action: {
                emergencyManager.deactivateEmergency()
            }) {
                Text("İptal")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(20)
            }
        }
        .padding()
        .background(Color.red)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private func requestLocationPermissionIfNeeded() {
        if locationManager.authorizationStatus == .notDetermined {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                locationManager.requestPermission()
            }
        }
    }
    
    private func checkEmergencyContactsSetup() {
        if emergencyManager.emergencyContacts.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showEmergencyContactsReminder()
            }
        }
    }
    
    private func showEmergencyContactsReminder() {
        let alert = UIAlertController(
            title: "Güvenlik İpucu",
            message: "Güvenliğiniz için acil durum kişileri eklemenizi öneririz.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Daha Sonra", style: .cancel))
        alert.addAction(UIAlertAction(title: "Şimdi Ekle", style: .default) { _ in
            selectedTab = 4 // Diğer tab'ına git
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
}

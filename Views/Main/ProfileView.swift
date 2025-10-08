import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var achievementViewModel = AchievementViewModel()
    @StateObject private var safetyManager = SafetyManager.shared
    
    @State private var showingAdminPanel = false
    @State private var showingEditProfile = false
    @State private var showingAchievements = false  // ✅ DÜZELTME: AchievementView için
    @State private var showingSafetySettings = false
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        List {
            // Profile Header
            profileHeaderSection
            
            // Safety Score Section
            safetyScoreSection
            
            // ✅ DÜZELTME: Başarımlar Section (inline)
            achievementsSection
            
            // Progress Section
            progressSection
            
            // Friends Section
            friendsSection
            
            // About Section
            aboutSection
            
            // Info Section
            infoSection
            
            // Interests Section
            if let interests = authViewModel.currentUser?.interests, !interests.isEmpty {
                interestsSection(interests)
            }
            
            // Admin Panel
            if authViewModel.isAdmin {
                adminSection
            }
            
            // Settings
            settingsSection
            
            // Logout
            logoutSection
        }
        .navigationTitle("Profil")
        .fullScreenCover(isPresented: $showingAdminPanel) {
            AdminPanelView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showingAchievements) {  // ✅ DÜZELTME: AchievementView açılacak
            NavigationView {
                AchievementView()
                    .environmentObject(authViewModel)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Kapat") {
                                showingAchievements = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingSafetySettings) {
            NavigationView {
                SafetySettingsView()
                    .environmentObject(authViewModel)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { _, newImage in
            if newImage != nil {
                // Profil fotoğrafını güncelle
            }
        }
    }
    
    private var profileHeaderSection: some View {
        Section {
            HStack(spacing: 16) {
                Button(action: { showingImagePicker = true }) {
                    ZStack(alignment: .bottomTrailing) {
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 70))
                                .foregroundColor(.blue)
                        }
                        
                        Image(systemName: "camera.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(authViewModel.currentUser?.name ?? "Kullanıcı")
                        .font(.title2)
                        .bold()
                    
                    Text(authViewModel.currentUser?.email ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", authViewModel.currentUser?.rating ?? 0))
                            .font(.caption)
                        
                        Divider()
                            .frame(height: 12)
                        
                        Image(systemName: "car.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("\(authViewModel.currentUser?.totalRides ?? 0) yolculuk")
                            .font(.caption)
                    }
                }
            }
            .padding(.vertical, 12)
        }
    }
    
    private var safetyScoreSection: some View {
        Section(header: Text("Güvenlik Skoru")) {
            if let user = authViewModel.currentUser {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: user.safetyScore / 100)
                            .stroke(
                                LinearGradient(
                                    colors: [safetyScoreColor(user.safetyScore), safetyScoreColor(user.safetyScore).opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 4) {
                            Text("\(Int(user.safetyScore))")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(safetyScoreColor(user.safetyScore))
                            Text("Güvenlik")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(spacing: 8) {
                        SafetyBadgeRow(
                            icon: "checkmark.shield.fill",
                            title: "Email Doğrulandı",
                            isCompleted: user.isVerified
                        )
                        SafetyBadgeRow(
                            icon: "phone.fill",
                            title: "Telefon Doğrulandı",
                            isCompleted: user.isPhoneVerified
                        )
                        SafetyBadgeRow(
                            icon: "person.2.fill",
                            title: "Acil Kişiler",
                            isCompleted: user.hasEmergencyContacts
                        )
                    }
                    
                    Button(action: { showingSafetySettings = true }) {
                        HStack {
                            Image(systemName: "shield.lefthalf.filled")
                            Text("Güvenlik Ayarları")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // ✅ DÜZELTME: Başarımlar Section
    private var achievementsSection: some View {
        Section(header: Text("Başarımlar")) {
            if let user = authViewModel.currentUser {
                VStack(spacing: 12) {
                    // XP ve Level
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Seviye \(user.level)")
                                .font(.headline)
                            Text("\(user.xp) XP")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                                .frame(width: 60, height: 60)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(user.xp % 100) / 100.0)
                                .stroke(Color.blue, lineWidth: 8)
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(-90))
                            
                            Text("\(user.xp % 100)%")
                                .font(.caption)
                                .bold()
                        }
                    }
                    
                    Divider()
                    
                    // Son Başarımlar
                    let unlockedAchievements = achievementViewModel.getUnlockedAchievements()
                    
                    if !unlockedAchievements.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Son Kazanılanlar")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Button(action: { showingAchievements = true }) {  // ✅ DÜZELTME
                                    HStack(spacing: 4) {
                                        Text("Tümünü Gör")
                                        Image(systemName: "chevron.right")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                }
                            }
                            
                            // Grid layout için
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(unlockedAchievements.prefix(8)) { achievement in
                                    VStack(spacing: 6) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.orange.opacity(0.1))
                                                .frame(width: 50, height: 50)
                                            
                                            Image(systemName: achievement.icon)
                                                .font(.title3)
                                                .foregroundColor(.orange)
                                        }
                                        
                                        Text(achievement.title)
                                            .font(.caption2)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                    }
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "trophy")
                                .font(.largeTitle)
                                .foregroundColor(.gray.opacity(0.5))
                            Text("Henüz başarım yok")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Yolculuklara katılarak başarım kazan!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                }
            }
        }
    }
    
    private var progressSection: some View {
        Section(header: Text("İstatistikler")) {
            if let user = authViewModel.currentUser {
                HStack {
                    StatCard(
                        icon: "car.fill",
                        value: "\(user.totalRides)",
                        label: "Yolculuk"
                    )
                    StatCard(
                        icon: "star.fill",
                        value: String(format: "%.1f", user.rating),
                        label: "Puan"
                    )
                    StatCard(
                        icon: "person.2.fill",
                        value: "\(user.friends.count)",
                        label: "Arkadaş"
                    )
                }
            }
        }
    }
    
    private var friendsSection: some View {
        Section(header: Text("Arkadaşlar")) {
            NavigationLink(destination: DiscoverView()
                .environmentObject(authViewModel)) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.purple)
                    Text("\(authViewModel.currentUser?.friends.count ?? 0) Arkadaş")
                    Spacer()
                }
            }
        }
    }
    
    private var aboutSection: some View {
        Section(header: Text("Hakkımda")) {
            if let bio = authViewModel.currentUser?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Bio eklenmemiş")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
    
    private var infoSection: some View {
        Section(header: Text("Bilgiler")) {
            if let user = authViewModel.currentUser {
                InfoDetailRow(icon: "building.2.fill", title: "Üniversite", value: user.university)
                
                if !user.department.isEmpty {
                    InfoDetailRow(icon: "book.fill", title: "Bölüm", value: user.department)
                }
                
                if !user.phoneNumber.isEmpty {
                    InfoDetailRow(icon: "phone.fill", title: "Telefon", value: user.phoneNumber)
                }
                
                InfoDetailRow(icon: "person.fill", title: "Cinsiyet", value: user.gender)
                
                InfoDetailRow(
                    icon: user.isVerified ? "checkmark.seal.fill" : "xmark.seal.fill",
                    title: "Durum",
                    value: user.isVerified ? "Doğrulanmış" : "Doğrulanmamış",
                    iconColor: user.isVerified ? .green : .orange
                )
            }
        }
    }
    
    private func interestsSection(_ interests: [String]) -> some View {
        Section(header: Text("İlgi Alanları")) {
            FlowLayout(spacing: 8) {
                ForEach(interests, id: \.self) { interest in
                    Text(interest)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(16)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var adminSection: some View {
        Section {
            Button(action: { showingAdminPanel = true }) {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(.orange)
                    Text("Yönetici Paneli")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var settingsSection: some View {
        Section {
            Button(action: { showingEditProfile = true }) {
                HStack {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.blue)
                    Text("Profili Düzenle")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
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
                    Text("Çıkış Yap")
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private func safetyScoreColor(_ score: Double) -> Color {
        if score >= 80 { return .green }
        if score >= 50 { return .orange }
        return .red
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views
struct SafetyBadgeRow: View {
    let icon: String
    let title: String
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(isCompleted ? .green : .gray)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(isCompleted ? .primary : .secondary)
            
            Spacer()
            
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .gray)
        }
    }
}

struct InfoDetailRow: View {
    let icon: String
    let title: String
    let value: String
    var iconColor: Color = .blue
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}   

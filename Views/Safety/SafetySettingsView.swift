import SwiftUI
import CoreLocation

struct SafetySettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var safetyManager = SafetyManager.shared
    @StateObject private var emergencyManager = EmergencyManager.shared
    @StateObject private var locationManager = LocationManager.shared
    
    @State private var showAddContact = false
    @State private var showVerificationSheet = false
    
    var body: some View {
        List {
            safetyScoreSection
            verificationSection
            emergencyContactsSection
            locationSection  // ✅ DÜZELTILDI
            safetyFeaturesSection
        }
        .navigationTitle("Güvenlik Ayarları")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddContact) {
            AddEmergencyContactView()
        }
        .sheet(isPresented: $showVerificationSheet) {
            PhoneVerificationView()
                .environmentObject(authViewModel)
        }
    }
    
    private var safetyScoreSection: some View {
        Section(header: Text("Güvenlik Skoru")) {
            if let user = authViewModel.currentUser {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(Int(user.safetyScore))%")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(safetyScoreColor(user.safetyScore))
                            Text("Güvenlik Skoru")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: user.safetyScore / 100)
                                .stroke(safetyScoreColor(user.safetyScore), lineWidth: 8)
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                        }
                    }
                    
                    Text(safetyScoreMessage(user.safetyScore))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private var verificationSection: some View {
        Section(header: Text("Kimlik Doğrulama")) {
            HStack {
                Image(systemName: "phone.fill")
                    .foregroundColor(.green)
                Text("Telefon Doğrulama")
                Spacer()
                
                if let user = authViewModel.currentUser, user.isPhoneVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                } else {
                    Button("Doğrula") {
                        showVerificationSheet = true
                    }
                    .font(.subheadline)
                }
            }
            
            HStack {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .foregroundColor(.blue)
                Text("Profil Fotoğrafı")
                Spacer()
                
                if authViewModel.currentUser?.isVerified == true {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                } else {
                    Button("Doğrula") {
                        safetyManager.requestPhotoVerification()
                    }
                    .font(.subheadline)
                }
            }
        }
    }
    
    private var emergencyContactsSection: some View {
        Section(header: Text("Acil Durum Kişileri")) {
            ForEach(emergencyManager.emergencyContacts) { contact in
                ContactRow(contact: contact)
            }
            
            Button(action: { showAddContact = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                    Text("Kişi Ekle")
                }
            }
        }
    }
    
    // ✅ DÜZELTME: Konum Ayarları - Settings'e yönlendirme
    private var locationSection: some View {
        Section(header: Text("Konum Ayarları"), footer: Text("Güvenliğiniz için konum izni önemlidir. Ayarlar uygulamasından değiştirebilirsiniz.")) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                Text("Konum İzni")
                Spacer()
                Text(locationStatusText)
                    .font(.caption)
                    .foregroundColor(locationStatusColor)
            }
            
            // ✅ Konum izni yoksa Settings'e yönlendir
            if locationManager.authorizationStatus != .authorizedAlways {
                Button(action: openLocationSettings) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Konum İzinlerini Değiştir")
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                            .font(.caption)
                    }
                }
            }
            
            // ✅ Always izni varsa arka plan takibi toggle
            if locationManager.authorizationStatus == .authorizedAlways {
                Toggle("Arka Plan Konum Takibi", isOn: Binding(
                    get: { locationManager.isTracking },
                    set: { enabled in
                        if enabled {
                            locationManager.startTracking()
                        } else {
                            locationManager.stopTracking()
                        }
                    }
                ))
            }
        }
    }
    
    private var safetyFeaturesSection: some View {
        Section(header: Text("Güvenlik Özellikleri")) {
            Toggle("Kadın-Kadın Yolculuk Modu", isOn: Binding(
                get: { safetyManager.womenOnlyModeEnabled },
                set: { safetyManager.toggleWomenOnlyMode($0) }
            ))
            
            Toggle("Güvenilir Kişilere Otomatik Bildir", isOn: $safetyManager.trustedContactsEnabled)
            
            NavigationLink(destination: EmergencyHistoryView()) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.orange)
                    Text("Acil Durum Geçmişi")
                }
            }
        }
    }
    
    // MARK: - Helpers
    private var locationStatusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined: return "Belirlenmedi"
        case .restricted: return "Kısıtlı"
        case .denied: return "Reddedildi"
        case .authorizedAlways: return "Her Zaman ✓"
        case .authorizedWhenInUse: return "Uygulama Açıkken"
        @unknown default: return "Bilinmiyor"
        }
    }
    
    private var locationStatusColor: Color {
        switch locationManager.authorizationStatus {
        case .authorizedAlways: return .green
        case .authorizedWhenInUse: return .orange
        case .denied, .restricted: return .red
        default: return .secondary
        }
    }
    
    // ✅ YENİ: Settings'e yönlendirme
    private func openLocationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func safetyScoreColor(_ score: Double) -> Color {
        if score >= 80 { return .green }
        if score >= 50 { return .orange }
        return .red
    }
    
    private func safetyScoreMessage(_ score: Double) -> String {
        if score >= 80 {
            return "Harika! Güvenlik skorunuz çok yüksek."
        } else if score >= 50 {
            return "İyi! Daha fazla doğrulama yaparak skorunuzu artırabilirsiniz."
        } else {
            return "Güvenlik skorunuzu artırmak için kimlik doğrulama yapın ve acil kişiler ekleyin."
        }
    }
}

struct EmergencyHistoryView: View {
    var body: some View {
        List {
            Text("Acil durum geçmişiniz burada görünecek")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Acil Durum Geçmişi")
        .navigationBarTitleDisplayMode(.inline)
    }
}

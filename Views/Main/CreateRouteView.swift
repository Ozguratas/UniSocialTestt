import SwiftUI

struct CreateRouteView: View {
    @EnvironmentObject var routeViewModel: RouteViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var startLocation = ""
    @State private var endLocation = ""
    @State private var departureDate = Date()
    @State private var availableSeats = 1
    @State private var vehicleInfo = ""
    @State private var meetingPoint = ""
    @State private var note = ""
    @State private var isRecurring = false
    @State private var selectedDays: Set<String> = []
    
    // Preferences
    @State private var smokingAllowed = false
    @State private var petsAllowed = false
    @State private var musicPreference = "Fark etmez"
    @State private var chatLevel = "Orta"
    @State private var genderPreference = "Hepsi"
    @State private var luggageSpace = "Orta"
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var scrollTarget: Int?
    
    let musicOptions = ["Sessiz", "Fark etmez", "Pop", "Rock", "Rap", "Klasik"]
    let chatLevels = ["Sessiz", "Az", "Orta", "Çok"]
    let genderOptions = ["Hepsi", "Erkek", "Kadın"]
    let luggageOptions = ["Az", "Orta", "Çok"]
    let weekDays = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"]
    
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                Form {
                    // Konum Bilgileri
                    Section(header: Text("Güzergah Bilgileri")) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Başlangıç Noktası")
                                    .font(.subheadline)
                                Text("*")
                                    .foregroundColor(.red)
                            }
                            TextField("Örn: Maslak", text: $startLocation)
                                .textContentType(.location)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Varış Noktası")
                                    .font(.subheadline)
                                Text("*")
                                    .foregroundColor(.red)
                            }
                            TextField("Örn: Kadıköy", text: $endLocation)
                                .textContentType(.location)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Buluşma Noktası (Opsiyonel)")
                                .font(.subheadline)
                            TextField("Örn: Maslak Metro", text: $meetingPoint)
                                .textContentType(.location)
                        }
                        
                        DatePicker("Kalkış Zamanı", selection: $departureDate, in: Date()...)
                            .datePickerStyle(.compact)
                            .environment(\.locale, Locale(identifier: "tr_TR"))
                    }
                    
                    // Araç ve Koltuk
                    Section(header: Text("Araç Bilgileri")) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Araç")
                                    .font(.subheadline)
                                Text("*")
                                    .foregroundColor(.red)
                            }
                            TextField("Örn: Renault Clio", text: $vehicleInfo)
                        }
                        
                        Stepper("Boş Koltuk: \(availableSeats)", value: $availableSeats, in: 1...4)
                    }
                    
                    // Tekrarlanan Yolculuk
                    Section(header: Text("Tekrarlama (Opsiyonel)")) {
                        Toggle("Tekrarlanan Yolculuk", isOn: $isRecurring)
                        
                        if isRecurring {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Hangi günler?")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                // Grid Layout yerine LazyVGrid kullan
                                LazyVGrid(columns: [
                                    GridItem(.adaptive(minimum: 80), spacing: 8)
                                ], spacing: 8) {
                                    ForEach(weekDays, id: \.self) { day in
                                        DayChipButton(
                                            day: day,
                                            isSelected: selectedDays.contains(day)
                                        ) {
                                            toggleDay(day)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                                
                                if !selectedDays.isEmpty {
                                    Text("Seçili: \(selectedDays.sorted().joined(separator: ", "))")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .id(1)
                    
                    // Tercihler - ScrollViewReader için id ekle
                    Section(header: Text("Yolculuk Tercihleri")) {
                        Toggle("Sigara İçilebilir", isOn: $smokingAllowed)
                        Toggle("Evcil Hayvan Kabul Edilir", isOn: $petsAllowed)
                        
                        Picker("Müzik Tercihi", selection: $musicPreference) {
                            ForEach(musicOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        
                        Picker("Sohbet Seviyesi", selection: $chatLevel) {
                            ForEach(chatLevels, id: \.self) { level in
                                Text(level).tag(level)
                            }
                        }
                        
                        Picker("Cinsiyet Tercihi", selection: $genderPreference) {
                            ForEach(genderOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        
                        Picker("Bagaj Alanı", selection: $luggageSpace) {
                            ForEach(luggageOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                    }
                    .id(2)
                    
                    // Not
                    Section(header: Text("Ek Bilgi (Opsiyonel)")) {
                        TextEditor(text: $note)
                            .frame(height: 80)
                    }
                    
                    // Oluştur Butonu
                    Section {
                        PrimaryButton(
                            title: "Güzergah Oluştur",
                            action: createRoute,
                            isEnabled: !startLocation.isEmpty && !endLocation.isEmpty && !vehicleInfo.isEmpty
                        )
                    }
                    
                    // Zorunlu alan uyarısı
                    Section {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("* ile işaretli alanlar zorunludur")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Yeni Güzergah")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
            .alert("Bilgi", isPresented: $showAlert) {
                Button("Tamam") {
                    if alertMessage.contains("oluşturuldu") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // Gün toggle fonksiyonu - DÜZELTİLDİ
    private func toggleDay(_ day: String) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
    
    func createRoute() {
        // Validation
        guard !startLocation.isEmpty else {
            alertMessage = "⚠️ Başlangıç noktası boş olamaz"
            showAlert = true
            return
        }
        
        guard !endLocation.isEmpty else {
            alertMessage = "⚠️ Varış noktası boş olamaz"
            showAlert = true
            return
        }
        
        guard !vehicleInfo.isEmpty else {
            alertMessage = "⚠️ Araç bilgisi boş olamaz"
            showAlert = true
            return
        }
        
        if isRecurring && selectedDays.isEmpty {
            alertMessage = "⚠️ Tekrarlanan yolculuk için en az bir gün seçmelisiniz"
            showAlert = true
            return
        }
        
        guard let currentUser = authViewModel.currentUser else {
            alertMessage = "❌ Kullanıcı bilgisi bulunamadı"
            showAlert = true
            return
        }
        
        // Basit koordinat simülasyonu (normalde geocoding yapılır)
        let startLat = 41.1057 + Double.random(in: -0.1...0.1)
        let startLng = 29.0250 + Double.random(in: -0.1...0.1)
        let endLat = 40.9902 + Double.random(in: -0.1...0.1)
        let endLng = 29.0244 + Double.random(in: -0.1...0.1)
        
        // Mesafe hesaplama (basitleştirilmiş)
        let distance = sqrt(pow(endLat - startLat, 2) + pow(endLng - startLng, 2)) * 111.0
        let duration = Int(distance * 2.5) // ~2.5 dk/km
        
        let preferences = RoutePreferences(
            smokingAllowed: smokingAllowed,
            petsAllowed: petsAllowed,
            musicPreference: musicPreference,
            chatLevel: chatLevel,
            genderPreference: genderPreference,
            luggageSpace: luggageSpace
        )
        
        let newRoute = Route(
            id: UUID().uuidString,
            driverId: currentUser.id,
            driverName: currentUser.name,
            driverRating: currentUser.rating,
            driverGender: currentUser.gender,
            startLocation: startLocation,
            endLocation: endLocation,
            startLatitude: startLat,
            startLongitude: startLng,
            endLatitude: endLat,
            endLongitude: endLng,
            departureTime: departureDate,
            availableSeats: availableSeats,
            passengers: [],
            vehicleInfo: vehicleInfo,
            isActive: true,
            isRecurring: isRecurring,
            recurringDays: isRecurring ? Array(selectedDays) : [],
            preferences: preferences,
            meetingPoint: meetingPoint.isEmpty ? startLocation : meetingPoint,
            estimatedDuration: duration,
            distance: distance,
            note: note
        )
        
        routeViewModel.createRoute(newRoute)
        
        alertMessage = "✅ Güzergah başarıyla oluşturuldu! 🚗"
        showAlert = true
        
        Logger.info("Route created: \(startLocation) -> \(endLocation)")
    }
}

// Gün seçimi için chip component - DÜZELTİLDİ
struct DayChipButton: View {
    let day: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(String(day.prefix(3)))
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
        .buttonStyle(.plain) // ÖNEMLİ: Form içinde default button style'ı engelle
    }
}

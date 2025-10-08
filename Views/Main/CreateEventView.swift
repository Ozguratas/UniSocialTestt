import SwiftUI

struct CreateEventView: View {
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var eventDate = Date().addingTimeInterval(3600)
    @State private var maxParticipants = 5
    @State private var selectedCategory: EventCategory = .social
    @State private var requirements: [String] = []
    @State private var newRequirement = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Etkinlik Bilgileri")) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Başlık")
                                .font(.subheadline)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        TextField("Örn: Kahve & Sohbet", text: $title)
                            .textContentType(.name)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Kategori")
                                .font(.subheadline)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        Picker("Kategori", selection: $selectedCategory) {
                            ForEach(EventCategory.allCases, id: \.self) { category in
                                HStack {
                                    Image(systemName: category.icon)
                                    Text(category.rawValue)
                                }
                                .tag(category)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Açıklama")
                                .font(.subheadline)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        TextEditor(text: $description)
                            .frame(height: 100)
                            .overlay(
                                Group {
                                    if description.isEmpty {
                                        Text("Etkinlik hakkında bilgi verin...")
                                            .foregroundColor(.gray.opacity(0.5))
                                            .padding(.leading, 5)
                                            .padding(.top, 8)
                                    }
                                },
                                alignment: .topLeading
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Konum")
                                .font(.subheadline)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        TextField("Örn: Starbucks Maslak", text: $location)
                            .textContentType(.location)
                    }
                }
                
                Section(header: Text("Tarih & Katılımcı")) {
                    DatePicker("Etkinlik Zamanı", selection: $eventDate, in: Date()...)
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "tr_TR"))
                    
                    Picker("Maksimum Katılımcı", selection: $maxParticipants) {
                        ForEach(2...50, id: \.self) { number in
                            Text("\(number) kişi").tag(number)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Gereksinimler (Opsiyonel)")) {
                    ForEach(requirements, id: \.self) { requirement in
                        HStack {
                            Text(requirement)
                            Spacer()
                            Button(action: {
                                requirements.removeAll { $0 == requirement }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Yeni gereksinim", text: $newRequirement)
                        
                        Button(action: addRequirement) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(newRequirement.isEmpty)
                    }
                }
                
                Section(header: Text("Önizleme")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text(eventDate.formatted(date: .long, time: .shortened))
                                .font(.caption)
                        }
                        
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.red)
                            Text(location.isEmpty ? "Konum belirtilmedi" : location)
                                .font(.caption)
                                .foregroundColor(location.isEmpty ? .secondary : .primary)
                        }
                        
                        HStack {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(.green)
                            Text("1/\(maxParticipants) katılımcı")
                                .font(.caption)
                        }
                        
                        HStack {
                            Image(systemName: selectedCategory.icon)
                                .foregroundColor(selectedCategory.color)
                            Text(selectedCategory.rawValue)
                                .font(.caption)
                        }
                    }
                }
                
                Section {
                    PrimaryButton(
                        title: "Etkinlik Oluştur",
                        action: createEvent,
                        isEnabled: !title.isEmpty && !description.isEmpty && !location.isEmpty
                    )
                }
                
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
            .navigationTitle("Yeni Etkinlik")
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
    
    private func addRequirement() {
        let trimmed = newRequirement.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        requirements.append(trimmed)
        newRequirement = ""
    }
    
    func createEvent() {
        guard !title.isEmpty else {
            alertMessage = "⚠️ Başlık boş olamaz"
            showAlert = true
            return
        }
        
        guard !description.isEmpty else {
            alertMessage = "⚠️ Açıklama boş olamaz"
            showAlert = true
            return
        }
        
        guard !location.isEmpty else {
            alertMessage = "⚠️ Konum boş olamaz"
            showAlert = true
            return
        }
        
        guard eventDate > Date() else {
            alertMessage = "⚠️ Etkinlik zamanı gelecekte olmalı"
            showAlert = true
            return
        }
        
        guard let currentUser = authViewModel.currentUser else {
            alertMessage = "❌ Kullanıcı bilgisi bulunamadı"
            showAlert = true
            return
        }
        
        let newEvent = Event(
            creatorId: currentUser.id,
            creatorName: currentUser.name,
            title: title,
            description: description,
            location: location,
            eventTime: eventDate,
            participants: [currentUser.id],
            maxParticipants: maxParticipants,
            category: selectedCategory,
            requirements: requirements
        )
        
        eventViewModel.createEvent(newEvent)
        
        alertMessage = "✅ Etkinlik başarıyla oluşturuldu! 🎉"
        showAlert = true
        
        Logger.info("Event created: \(title)")
    }
}

// MARK: - EventCategory Extension
extension EventCategory {
    var icon: String {
        switch self {
        case .social: return "person.3.fill"
        case .sports: return "figure.run"
        case .academic: return "book.fill"
        case .cultural: return "theatermasks.fill"
        case .volunteer: return "heart.fill"
        case .other: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .social: return .purple
        case .sports: return .green
        case .academic: return .blue
        case .cultural: return .orange
        case .volunteer: return .pink
        case .other: return .gray
        }
    }
}

import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var bio = ""
    @State private var phoneNumber = ""
    @State private var department = ""
    @State private var selectedInterests: Set<String> = []
    @State private var customInterest = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let availableInterests = [
        "Müzik", "Spor", "Sinema", "Kitap", "Seyahat",
        "Yemek", "Teknoloji", "Sanat", "Fotoğrafçılık", "Oyun"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kişisel Bilgiler")) {
                    TextField("Ad Soyad", text: $name)
                        .textContentType(.name)
                    
                    // ✅ DÜZELTME: Telefon düzenlenebilir
                    TextField("Telefon", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    
                    // ✅ DÜZELTME: Bölüm düzenlenebilir
                    TextField("Bölüm", text: $department)
                }
                
                Section(header: Text("Hakkımda"), footer: Text("\(bio.count)/\(AppConstants.ValidationRules.maxBioLength)")) {
                    TextEditor(text: $bio)
                        .frame(height: 100)
                        .onChange(of: bio) { oldValue, newValue in
                            if newValue.count > AppConstants.ValidationRules.maxBioLength {
                                bio = String(newValue.prefix(AppConstants.ValidationRules.maxBioLength))
                            }
                        }
                }
                
                Section(header: Text("İlgi Alanları")) {
                    // ✅ DÜZELTME: FlowLayout ile yan yana ama ekrana sığacak şekilde
                    FlowLayout(spacing: 8) {
                        ForEach(availableInterests, id: \.self) { interest in
                            InterestChip(
                                interest: interest,
                                isSelected: selectedInterests.contains(interest),
                                action: {
                                    toggleInterest(interest)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                    
                    HStack {
                        TextField("Özel ilgi alanı ekle", text: $customInterest)
                        
                        Button(action: addCustomInterest) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(customInterest.isEmpty)
                    }
                    
                    if !selectedInterests.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Seçili: \(selectedInterests.count)/\(AppConstants.Limits.maxInterests)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // ✅ DÜZELTME: FlowLayout ile silme butonları
                            FlowLayout(spacing: 8) {
                                ForEach(Array(selectedInterests), id: \.self) { interest in
                                    HStack(spacing: 4) {
                                        Text(interest)
                                            .font(.caption)
                                        Button(action: {
                                            selectedInterests.remove(interest)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(16)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    PrimaryButton(
                        title: "Kaydet",
                        action: saveProfile,
                        isEnabled: !name.isEmpty
                    )
                }
            }
            .navigationTitle("Profili Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadUserData()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
            .alert("Bilgi", isPresented: $showAlert) {
                Button("Tamam") {
                    if alertMessage.contains("kaydedildi") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func toggleInterest(_ interest: String) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else {
            if selectedInterests.count < AppConstants.Limits.maxInterests {
                selectedInterests.insert(interest)
            } else {
                alertMessage = "En fazla \(AppConstants.Limits.maxInterests) ilgi alanı seçebilirsiniz"
                showAlert = true
            }
        }
    }
    
    func loadUserData() {
        guard let user = authViewModel.currentUser else { return }
        name = user.name
        bio = user.bio
        phoneNumber = user.phoneNumber
        department = user.department
        selectedInterests = Set(user.interests)
    }
    
    func addCustomInterest() {
        let trimmed = customInterest.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if selectedInterests.count >= AppConstants.Limits.maxInterests {
            alertMessage = "En fazla \(AppConstants.Limits.maxInterests) ilgi alanı seçebilirsiniz"
            showAlert = true
            return
        }
        
        if selectedInterests.contains(trimmed) {
            alertMessage = "Bu ilgi alanı zaten ekli"
            showAlert = true
            return
        }
        
        selectedInterests.insert(trimmed)
        customInterest = ""
    }
    
    func saveProfile() {
        guard !name.isEmpty else {
            alertMessage = "Ad Soyad boş olamaz"
            showAlert = true
            return
        }
        
        authViewModel.updateProfile(
            name: name,
            bio: bio,
            phoneNumber: phoneNumber,
            department: department,
            interests: Array(selectedInterests)
        )
        
        alertMessage = "Profil başarıyla kaydedildi! ✅"
        showAlert = true
    }
}

struct InterestChip: View {
    let interest: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(interest)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

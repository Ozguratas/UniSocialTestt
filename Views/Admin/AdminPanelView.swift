import SwiftUI

struct AdminPanelView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingCreateKey = false
    
    var body: some View {
        NavigationView {
            List(authViewModel.getAllInviteKeys()) { key in
                VStack(alignment: .leading, spacing: 4) {
                    Text(key.key)
                        .font(.headline)
                    HStack {
                        Text(key.isUsed ? "Kullanılmış" : "Aktif")
                            .font(.caption)
                            .foregroundColor(key.isUsed ? .red : .green)
                        if key.maxUses > 1 {
                            Text("(\(key.currentUses)/\(key.maxUses))")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    if let usedBy = key.usedByName {
                        Text("Kullanan: \(usedBy)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        authViewModel.deleteInviteKey(key: key.key)
                    } label: {
                        Label("Sil", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Yönetici Paneli")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateKey = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingCreateKey) {
                CreateInviteKeyView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

struct CreateInviteKeyView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var keyName = ""
    @State private var maxUses = 1
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Anahtar Bilgileri")) {
                    FormTextField(
                        placeholder: "ANAHTAR ADI",
                        text: $keyName,
                        autocapitalization: .characters,
                        validation: { key in
                            Validator.validateInviteKey(key)
                        }
                    )
                }
                
                Section(header: Text("Kullanım")) {
                    Picker("Maksimum Kullanım", selection: $maxUses) {
                        Text("Tek Kullanım").tag(1)
                        Text("5 Kullanım").tag(5)
                        Text("10 Kullanım").tag(10)
                        Text("25 Kullanım").tag(25)
                    }
                }
                
                Section {
                    PrimaryButton(
                        title: "Oluştur",
                        action: createKey,
                        isEnabled: !keyName.isEmpty
                    )
                }
            }
            .navigationTitle("Yeni Anahtar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
            .alert("Bilgi", isPresented: $showAlert) {
                Button("Tamam") {
                    if alertMessage.contains("başarıyla") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // ÖNEMLİ: Bu fonksiyon body DİŞINDA olmalı!
    private func createKey() {
        let result = authViewModel.createInviteKey(
            key: keyName,
            maxUses: maxUses,
            expiresAt: nil
        )
        
        switch result {
        case .success:
            alertMessage = "'\(keyName)' başarıyla oluşturuldu!"
            showAlert = true
        case .failure(let error):
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

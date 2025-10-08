import SwiftUI

struct TrustedContactsView: View {
    @StateObject private var emergencyManager = EmergencyManager.shared
    @State private var showAddContact = false
    
    var body: some View {
        NavigationView {
            List {
                if emergencyManager.emergencyContacts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Henüz acil kişi eklenmedi")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Güvenliğiniz için en az bir kişi ekleyin")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(emergencyManager.emergencyContacts) { contact in
                        ContactRow(contact: contact)
                    }
                    .onDelete(perform: deleteContacts)
                }
            }
            .navigationTitle("Acil Kişiler")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddContact = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddContact) {
                AddEmergencyContactView()
            }
        }
    }
    
    private func deleteContacts(at offsets: IndexSet) {
        for index in offsets {
            let contact = emergencyManager.emergencyContacts[index]
            emergencyManager.removeEmergencyContact(contact)
        }
    }
}

struct ContactRow: View {
    let contact: EmergencyContact
    @StateObject private var emergencyManager = EmergencyManager.shared
    @State private var showEditSheet = false
    
    var body: some View {
        Button(action: { showEditSheet = true }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(contact.isPrimary ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                    
                    Text(String(contact.name.prefix(1)))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(contact.isPrimary ? .white : .primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(contact.name)
                            .font(.headline)
                        
                        if contact.isPrimary {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text(contact.relationship)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(contact.phoneNumber)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    HStack(spacing: 8) {
                        if contact.notifyViaSMS {
                            Label("SMS", systemImage: "message.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        
                        if contact.notifyViaWhatsApp {
                            Label("WhatsApp", systemImage: "message.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showEditSheet) {
            EditEmergencyContactView(contact: contact)
        }
    }
}

// MARK: - Add Emergency Contact View
struct AddEmergencyContactView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var emergencyManager = EmergencyManager.shared
    
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var relationship = "Aile"
    @State private var notifyViaSMS = true
    @State private var notifyViaWhatsApp = false
    @State private var isPrimary = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let relationships = ["Aile", "Arkadaş", "Eş", "Kardeş", "Ebeveyn", "Diğer"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kişi Bilgileri")) {
                    TextField("Ad Soyad", text: $name)
                        .textContentType(.name)
                    
                    TextField("Telefon Numarası", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    
                    Picker("İlişki", selection: $relationship) {
                        ForEach(relationships, id: \.self) { rel in
                            Text(rel)
                        }
                    }
                }
                
                Section(header: Text("Bildirim Tercihleri")) {
                    Toggle("SMS ile bildir", isOn: $notifyViaSMS)
                    Toggle("WhatsApp ile bildir", isOn: $notifyViaWhatsApp)
                    Toggle("Birincil kişi olarak ayarla", isOn: $isPrimary)
                }
                
                Section(footer: Text("Birincil kişiler acil durumlarda otomatik olarak bilgilendirilir.")) {
                    Button(action: addContact) {
                        HStack {
                            Spacer()
                            Text("Kaydet")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(name.isEmpty || phoneNumber.isEmpty)
                }
            }
            .navigationTitle("Acil Kişi Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
            .alert("Bilgi", isPresented: $showAlert) {
                Button("Tamam") {
                    if alertMessage.contains("eklendi") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func addContact() {
        guard !name.isEmpty, !phoneNumber.isEmpty else {
            alertMessage = "Lütfen tüm alanları doldurun"
            showAlert = true
            return
        }
        
        let newContact = EmergencyContact(
            id: UUID().uuidString,
            name: name,
            phoneNumber: phoneNumber,
            relationship: relationship,
            notifyViaSMS: notifyViaSMS,
            notifyViaWhatsApp: notifyViaWhatsApp,
            isPrimary: isPrimary
        )
        
        emergencyManager.addEmergencyContact(newContact)
        
        alertMessage = "Kişi başarıyla eklendi!"
        showAlert = true
    }
}

// MARK: - Edit Emergency Contact View
struct EditEmergencyContactView: View {
    let contact: EmergencyContact
    @Environment(\.dismiss) var dismiss
    @StateObject private var emergencyManager = EmergencyManager.shared
    
    @State private var name: String
    @State private var phoneNumber: String
    @State private var relationship: String
    @State private var notifyViaSMS: Bool
    @State private var notifyViaWhatsApp: Bool
    @State private var isPrimary: Bool
    
    let relationships = ["Aile", "Arkadaş", "Eş", "Kardeş", "Ebeveyn", "Diğer"]
    
    init(contact: EmergencyContact) {
        self.contact = contact
        _name = State(initialValue: contact.name)
        _phoneNumber = State(initialValue: contact.phoneNumber)
        _relationship = State(initialValue: contact.relationship)
        _notifyViaSMS = State(initialValue: contact.notifyViaSMS)
        _notifyViaWhatsApp = State(initialValue: contact.notifyViaWhatsApp)
        _isPrimary = State(initialValue: contact.isPrimary)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kişi Bilgileri")) {
                    TextField("Ad Soyad", text: $name)
                    TextField("Telefon Numarası", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    
                    Picker("İlişki", selection: $relationship) {
                        ForEach(relationships, id: \.self) { rel in
                            Text(rel)
                        }
                    }
                }
                
                Section(header: Text("Bildirim Tercihleri")) {
                    Toggle("SMS ile bildir", isOn: $notifyViaSMS)
                    Toggle("WhatsApp ile bildir", isOn: $notifyViaWhatsApp)
                    Toggle("Birincil kişi", isOn: $isPrimary)
                }
                
                Section {
                    Button(action: saveChanges) {
                        HStack {
                            Spacer()
                            Text("Değişiklikleri Kaydet")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    
                    Button(role: .destructive, action: deleteContact) {
                        HStack {
                            Spacer()
                            Text("Kişiyi Sil")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Kişiyi Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
        }
    }
    
    private func saveChanges() {
        emergencyManager.removeEmergencyContact(contact)
        
        let updatedContact = EmergencyContact(
            id: contact.id,
            name: name,
            phoneNumber: phoneNumber,
            relationship: relationship,
            notifyViaSMS: notifyViaSMS,
            notifyViaWhatsApp: notifyViaWhatsApp,
            isPrimary: isPrimary
        )
        
        emergencyManager.addEmergencyContact(updatedContact)
        dismiss()
    }
    
    private func deleteContact() {
        emergencyManager.removeEmergencyContact(contact)
        dismiss()
    }
}

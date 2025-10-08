import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 1
    @State private var inviteKey = ""
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var university = "İstanbul Teknik Üniversitesi"
    @State private var phoneNumber = ""
    @State private var gender = "Belirtilmemiş"
    @State private var department = ""
    @State private var agreedToTerms = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isValidatingKey = false
    @State private var isRegistering = false
    
    let universities = [
        "İstanbul Teknik Üniversitesi",
        "Boğaziçi Üniversitesi",
        "İstanbul Üniversitesi",
        "ODTÜ",
        "Bilkent Üniversitesi"
    ]
    
    let genders = ["Erkek", "Kadın", "Belirtilmemiş"]
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress Indicator
                HStack(spacing: 8) {
                    ForEach(1...3, id: \.self) { step in
                        Circle()
                            .fill(currentStep >= step ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                    }
                }
                .padding(.top, 20)
                
                if currentStep == 1 {
                    inviteKeyStep
                } else if currentStep == 2 {
                    personalInfoStep
                } else {
                    finalStep
                }
                
                Spacer()
            }
            .navigationTitle("Kayıt Ol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
            .alert("Bilgi", isPresented: $showAlert) {
                Button("Tamam", role: .cancel) {
                    // Eğer kayıt başarılıysa otomatik giriş yapıldı, dismiss edelim
                    if alertMessage.contains("başarılı") && authViewModel.isAuthenticated {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    var inviteKeyStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding(.top, 40)
            
            Text("Davet Anahtarı")
                .font(.title2)
                .bold()
            
            Text("UniSocial'e katılmak için davet anahtarı gerekli")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            VStack(spacing: 15) {
                FormTextField(
                    placeholder: "DAVET ANAHTARI",
                    text: $inviteKey,
                    autocapitalization: .characters,
                    validation: { key in
                        Validator.validateInviteKey(key)
                    }
                )
                .padding(.horizontal, 30)
                
                if isValidatingKey {
                    ProgressView()
                } else {
                    PrimaryButton(
                        title: "Devam Et",
                        action: validateKey,
                        isEnabled: !inviteKey.isEmpty
                    )
                    .padding(.horizontal, 30)
                }
            }
        }
    }
    
    var personalInfoStep: some View {
        Form {
            Section(header: Text("Kişisel Bilgiler")) {
                TextField("Ad Soyad", text: $name)
                    .textContentType(.name)
                
                FormTextField(
                    placeholder: "E-posta (.edu.tr)",
                    text: $email,
                    keyboardType: .emailAddress,
                    autocapitalization: .never,
                    validation: { email in
                        Validator.validateEmail(email)
                    }
                )
                
                TextField("Telefon (Opsiyonel)", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                
                Picker("Cinsiyet", selection: $gender) {
                    ForEach(genders, id: \.self) { g in
                        Text(g)
                    }
                }
            }
            
            Section(header: Text("Üniversite")) {
                Picker("Üniversite", selection: $university) {
                    ForEach(universities, id: \.self) { uni in
                        Text(uni)
                    }
                }
                
                TextField("Bölüm (Opsiyonel)", text: $department)
            }
            
            Section(header: Text("Güvenlik")) {
                FormSecureField(
                    placeholder: "Şifre",
                    text: $password,
                    validation: { password in
                        Validator.validatePassword(password)
                    }
                )
                
                SecureField("Şifre Tekrar", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
                    Text("Şifreler eşleşmiyor")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Section {
                HStack {
                    SecondaryButton(title: "Geri", action: { currentStep = 1 })
                    PrimaryButton(
                        title: "Devam",
                        action: validatePersonalInfo,
                        isEnabled: !name.isEmpty && !email.isEmpty && !password.isEmpty && password == confirmPassword
                    )
                }
            }
        }
    }
    
    var finalStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .padding(.top, 40)
                
                Text("Son Adım!")
                    .font(.title2)
                    .bold()
                
                VStack(spacing: 12) {
                    InfoRow(icon: "person.fill", title: "Ad Soyad", value: name)
                    InfoRow(icon: "envelope.fill", title: "E-posta", value: email)
                    InfoRow(icon: "building.2.fill", title: "Üniversite", value: university)
                    if !department.isEmpty {
                        InfoRow(icon: "book.fill", title: "Bölüm", value: department)
                    }
                    if !phoneNumber.isEmpty {
                        InfoRow(icon: "phone.fill", title: "Telefon", value: phoneNumber)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Toggle(isOn: $agreedToTerms) {
                    Text("Kullanım koşullarını kabul ediyorum")
                        .font(.subheadline)
                }
                .padding()
                
                if isRegistering {
                    ProgressView("Kayıt oluşturuluyor...")
                        .padding()
                } else {
                    HStack(spacing: 15) {
                        SecondaryButton(title: "Geri", action: { currentStep = 2 })
                        PrimaryButton(
                            title: "Kayıt Ol",
                            action: signUp,
                            isEnabled: agreedToTerms && !isRegistering
                        )
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    func validateKey() {
        isValidatingKey = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isValidatingKey = false
            let result = authViewModel.validateInviteKey(inviteKey)
            switch result {
            case .success:
                withAnimation { currentStep = 2 }
            case .failure(let error):
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
    
    func validatePersonalInfo() {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            alertMessage = "Lütfen zorunlu alanları doldurun"
            showAlert = true
            return
        }
        
        let emailValidation = Validator.validateEmail(email)
        guard emailValidation.isValid else {
            alertMessage = emailValidation.errorMessage ?? "Geçersiz e-posta"
            showAlert = true
            return
        }
        
        let passwordValidation = Validator.validatePassword(password)
        guard passwordValidation.isValid else {
            alertMessage = passwordValidation.errorMessage ?? "Geçersiz şifre"
            showAlert = true
            return
        }
        
        guard password == confirmPassword else {
            alertMessage = "Şifreler eşleşmiyor"
            showAlert = true
            return
        }
        
        withAnimation { currentStep = 3 }
    }
    
    func signUp() {
        isRegistering = true
        
        // authViewModel'in yeni signUp fonksiyonunu çağır
        authViewModel.signUp(
            name: name,
            email: email,
            password: password,
            university: university,
            inviteKey: inviteKey,
            phoneNumber: phoneNumber,
            gender: gender,
            department: department
        )
        
        // Kısa bir gecikme sonrası kontrol et
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isRegistering = false
            
            if authViewModel.isAuthenticated {
                alertMessage = "Kayıt başarılı! Hoş geldin \(name) 🎉"
                showAlert = true
            } else if let error = authViewModel.errorMessage {
                alertMessage = error
                showAlert = true
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.blue).frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundColor(.secondary)
                Text(value).font(.subheadline)
            }
            Spacer()
        }
    }
}

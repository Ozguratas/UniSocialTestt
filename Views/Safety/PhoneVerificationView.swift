import SwiftUI

struct PhoneVerificationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var safetyManager = SafetyManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var isCodeSent = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "phone.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                Text("Telefon Doğrulama")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if !isCodeSent {
                    phoneNumberSection
                } else {
                    verificationCodeSection
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
            .alert("Bilgi", isPresented: $showAlert) {
                Button("Tamam") {
                    if alertMessage.contains("başarılı") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var phoneNumberSection: some View {
        VStack(spacing: 16) {
            Text("Telefon numaranızı girin")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField("+90 555 123 4567", text: $phoneNumber)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            if isLoading {
                ProgressView()
            } else {
                Button(action: sendVerificationCode) {
                    Text("Doğrulama Kodu Gönder")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(phoneNumber.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(phoneNumber.isEmpty)
                .padding(.horizontal)
            }
        }
    }
    
    private var verificationCodeSection: some View {
        VStack(spacing: 16) {
            Text("Telefonunuza gönderilen 6 haneli kodu girin")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            TextField("Doğrulama Kodu", text: $verificationCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            if isLoading {
                ProgressView()
            } else {
                Button(action: verifyCode) {
                    Text("Doğrula")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(verificationCode.isEmpty ? Color.gray : Color.green)
                        .cornerRadius(12)
                }
                .disabled(verificationCode.isEmpty)
                .padding(.horizontal)
                
                Button(action: { isCodeSent = false }) {
                    Text("Numarayı Değiştir")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func sendVerificationCode() {
        isLoading = true
        
        safetyManager.verifyPhoneNumber(phoneNumber) { success in
            isLoading = false
            
            if success {
                isCodeSent = true
                alertMessage = "Doğrulama kodu gönderildi!"
                showAlert = true
            } else {
                alertMessage = "Kod gönderilemedi. Lütfen tekrar deneyin."
                showAlert = true
            }
        }
    }
    
    private func verifyCode() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            
            let isValid = safetyManager.confirmVerificationCode(phoneNumber, code: verificationCode)
            
            if isValid {
                alertMessage = "Telefon numaranız başarıyla doğrulandı! ✅"
                showAlert = true
            } else {
                alertMessage = "Geçersiz kod. Lütfen tekrar deneyin."
                showAlert = true
            }
        }
    }
}

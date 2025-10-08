import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    Text("UniSocial")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Üniversite Sosyal Platform")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    VStack(spacing: 15) {
                        FormTextField(
                            placeholder: "E-posta",
                            text: $email,
                            keyboardType: .emailAddress,
                            autocapitalization: .never,
                            validation: { email in
                                Validator.validateEmail(email)
                            }
                        )
                        
                        FormSecureField(
                            placeholder: "Şifre",
                            text: $password,
                            validation: { password in
                                Validator.validatePassword(password)
                            }
                        )
                        
                        PrimaryButton(
                            title: "Giriş Yap",
                            action: {
                                authViewModel.signIn(email: email, password: password)
                            },
                            isEnabled: !email.isEmpty && !password.isEmpty,
                            isLoading: authViewModel.isLoading
                        )
                        .padding(.top, 10)
                        
                        Button(action: { showingSignUp = true }) {
                            Text("Hesabın yok mu? Kayıt Ol")
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 40)
                }
                
                if authViewModel.isLoading {
                    LoadingOverlay(message: "Giriş yapılıyor...")
                }
            }
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
                    .environmentObject(authViewModel)
            }
            .alert("Hata", isPresented: $authViewModel.showError) {
                Button("Tamam") { authViewModel.showError = false }
            } message: {
                Text(authViewModel.errorMessage ?? "Bilinmeyen hata")
            }
        }
    }
}

import SwiftUI

struct FormTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .never
    var validation: ((String) -> ValidationResult)?
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .onChange(of: text) { oldValue, newValue in
                    if showError { validateInput() }
                }
                .onSubmit { validateInput() }
            
            if showError && !errorMessage.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill").font(.caption)
                    Text(errorMessage).font(.caption)
                }
                .foregroundColor(.red)
            }
        }
    }
    
    @MainActor
    private func validateInput() {
        guard let validation = validation else {
            showError = false
            return
        }
        let result = validation(text)
        showError = !result.isValid
        errorMessage = result.errorMessage ?? ""
    }
}

struct FormSecureField: View {
    let placeholder: String
    @Binding var text: String
    var validation: ((String) -> ValidationResult)?
    
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSecured = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if isSecured {
                    SecureField(placeholder, text: $text, onCommit: { validateInput() })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    TextField(placeholder, text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit { validateInput() }
                }
                
                Button(action: { isSecured.toggle() }) {
                    Image(systemName: isSecured ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 8)
            }
            .onChange(of: text) { oldValue, newValue in
                if showError { validateInput() }
            }
            
            if showError && !errorMessage.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill").font(.caption)
                    Text(errorMessage).font(.caption)
                }
                .foregroundColor(.red)
            }
        }
    }
    
    @MainActor
    private func validateInput() {
        guard let validation = validation else {
            showError = false
            return
        }
        let result = validation(text)
        showError = !result.isValid
        errorMessage = result.errorMessage ?? ""
    }
}

struct LoadingOverlay: View {
    var message: String = "Yükleniyor..."
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                Text(message)
                    .foregroundColor(.white)
                    .font(.subheadline)
            }
            .padding(30)
            .background(Color.black.opacity(0.7))
            .cornerRadius(16)
        }
    }
}

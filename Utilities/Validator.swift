
import Foundation

enum ValidationResult {
    case success
    case failure(String)
    
    var isValid: Bool {
        if case .success = self { return true }
        return false
    }
    
    var errorMessage: String? {
        if case .failure(let message) = self { return message }
        return nil
    }
}

struct Validator {
    static func validateEmail(_ email: String) -> ValidationResult {
        guard !email.isEmpty else { return .failure("E-posta boş olamaz") }
        
        // Trim ve lowercase yap
        let trimmed = email.trimmingCharacters(in: .whitespaces).lowercased()
        
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        guard NSPredicate(format:"SELF MATCHES %@", regex).evaluate(with: trimmed) else {
            return .failure("Geçersiz e-posta formatı")
        }
        
        guard trimmed.hasSuffix(".edu.tr") else {
            return .failure("Sadece .edu.tr uzantılı e-postalar kabul edilir")
        }
        
        return .success
    }
    
    static func validatePassword(_ password: String) -> ValidationResult {
        guard !password.isEmpty else { return .failure("Şifre boş olamaz") }
        guard password.count >= AppConstants.ValidationRules.minPasswordLength else {
            return .failure("Şifre en az \(AppConstants.ValidationRules.minPasswordLength) karakter olmalı")
        }
        let hasUpper = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLower = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        if !hasUpper { return .failure("Şifre büyük harf içermeli") }
        if !hasLower { return .failure("Şifre küçük harf içermeli") }
        if !hasNumber { return .failure("Şifre rakam içermeli") }
        return .success
    }
    
    static func validateInviteKey(_ key: String) -> ValidationResult {
        guard !key.isEmpty else { return .failure("Davet anahtarı boş olamaz") }
        guard key.count >= AppConstants.ValidationRules.minInviteKeyLength else {
            return .failure("Davet anahtarı çok kısa")
        }
        return .success
    }
}

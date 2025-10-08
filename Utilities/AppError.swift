import Foundation

enum AppError: LocalizedError {
    case invalidCredentials
    case invalidInviteKey
    case usedInviteKey
    case duplicateInviteKey
    case validationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "E-posta veya şifre hatalı"
        case .invalidInviteKey: return "Geçersiz davet anahtarı"
        case .usedInviteKey: return "Bu anahtar kullanılmış"
        case .duplicateInviteKey: return "Bu anahtar zaten mevcut"
        case .validationFailed(let msg): return msg
        }
    }
}

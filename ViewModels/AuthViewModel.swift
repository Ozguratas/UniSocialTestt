import Foundation
import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isAdmin = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var isLoading = false
    
    private var validInviteKeys: [String: InviteKey] = [:]
    
    init() {
        checkExistingSession()
        loadInviteKeys()
    }
    
    private func checkExistingSession() {
        if LocalStorageManager.shared.isAuthenticated(),
           let user = LocalStorageManager.shared.loadUserSession() {
            self.currentUser = user
            self.isAuthenticated = true
            self.isAdmin = user.email == "admin@unisocial.com"
            Logger.info("Session restored for: \(user.email)")
        }
    }
    
    private func loadInviteKeys() {
        let cached = LocalStorageManager.shared.loadCachedInviteKeys()
        if !cached.isEmpty {
            for key in cached {
                validInviteKeys[key.key] = key
            }
        } else {
            loadDefaultKeys()
        }
    }
    
    private func loadDefaultKeys() {
        validInviteKeys = [
            "UNISOCIAL2025": InviteKey(
                id: "1",
                key: "UNISOCIAL2025",
                createdBy: "admin",
                createdAt: Date(),
                isUsed: false,
                maxUses: 1,
                currentUses: 0
            ),
            "MULTIUSE2025": InviteKey(
                id: "2",
                key: "MULTIUSE2025",
                createdBy: "admin",
                createdAt: Date(),
                isUsed: false,
                maxUses: 10,
                currentUses: 0
            )
        ]
        saveInviteKeys()
    }
    
    private func saveInviteKeys() {
        LocalStorageManager.shared.cacheInviteKeys(Array(validInviteKeys.values))
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) {
        isLoading = true
        
        let isAdminLogin = email.lowercased() == "admin@unisocial.com"
        
        if !isAdminLogin {
            let emailValidation = Validator.validateEmail(email)
            guard emailValidation.isValid else {
                errorMessage = emailValidation.errorMessage
                showError = true
                isLoading = false
                return
            }
            
            let passwordValidation = Validator.validatePassword(password)
            guard passwordValidation.isValid else {
                errorMessage = passwordValidation.errorMessage
                showError = true
                isLoading = false
                return
            }
        } else {
            guard !password.isEmpty else {
                errorMessage = "Şifre boş olamaz"
                showError = true
                isLoading = false
                return
            }
        }
        
        if isAdminLogin {
            self.isAdmin = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.currentUser = User(
                id: UUID().uuidString,
                name: isAdminLogin ? "Admin" : "Test User",
                email: email,
                university: "İTÜ",
                profileImage: "person.circle.fill",
                rating: 4.5,
                totalRides: 12,
                phoneNumber: "+90 555 555 5555",
                isVerified: true,
                bio: "Test bio",
                interests: ["Müzik", "Spor"],
                friends: [],
                blockedUsers: [],
                gender: "Erkek",
                department: "Bilgisayar Mühendisliği",
                graduationYear: 2025,
                level: 1,
                xp: 0,
                achievements: [],
                totalReviews: 0
            )
            
            LocalStorageManager.shared.saveUserSession(self.currentUser!)
            self.isAuthenticated = true
            self.isLoading = false
            Logger.info("User signed in: \(email)")
        }
    }
    
    // MARK: - Sign Up
    func signUp(name: String, email: String, password: String, university: String, inviteKey: String, phoneNumber: String = "", gender: String = "Belirtilmemiş", department: String = "") {
        isLoading = true
        
        // Invite key validation
        let keyValidation = validateInviteKey(inviteKey)
        switch keyValidation {
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
            return
        case .success:
            break
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Yeni kullanıcı oluştur
            let userId = UUID().uuidString
            let newUser = User(
                id: userId,
                name: name,  // ARTIK GERÇEK İSİM!
                email: email,
                university: university,
                profileImage: "person.circle.fill",
                rating: 0.0,
                totalRides: 0,
                phoneNumber: phoneNumber,
                isVerified: false,
                bio: "Merhaba! UniSocial'e yeni katıldım 👋",
                interests: [],
                friends: [],
                blockedUsers: [],
                gender: gender,
                department: department,
                graduationYear: Calendar.current.component(.year, from: Date()) + 4,
                level: 1,
                xp: 0,
                achievements: [],
                totalReviews: 0
            )
            
            // Invite key'i kullan
            self.useInviteKey(inviteKey, userId: userId, userName: name, userEmail: email)
            
            // Session'ı kaydet ve giriş yap
            LocalStorageManager.shared.saveUserSession(newUser)
            self.currentUser = newUser
            self.isAuthenticated = true
            self.isLoading = false
            
            Logger.info("User registered and signed in: \(email) - \(name)")
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        LocalStorageManager.shared.clearSession()
        self.currentUser = nil
        self.isAuthenticated = false
        self.isAdmin = false
        Logger.info("User signed out")
    }
    
    // MARK: - Update Profile
    func updateProfile(name: String, bio: String, phoneNumber: String, department: String, interests: [String]) {
        guard var user = currentUser else { return }
        
        user.name = name
        user.bio = bio
        user.phoneNumber = phoneNumber
        user.department = department
        user.interests = interests
        
        self.currentUser = user
        LocalStorageManager.shared.saveUserSession(user)
        Logger.info("Profile updated for: \(user.email)")
    }
    
    // MARK: - Invite Keys
    func validateInviteKey(_ key: String) -> Result<Void, AppError> {
        let validation = Validator.validateInviteKey(key)
        guard validation.isValid else {
            return .failure(.validationFailed(validation.errorMessage ?? "Invalid key"))
        }
        
        guard let inviteKey = validInviteKeys[key.uppercased()] else {
            return .failure(.invalidInviteKey)
        }
        
        if inviteKey.maxUses > 1 {
            if inviteKey.currentUses >= inviteKey.maxUses {
                return .failure(.usedInviteKey)
            }
        } else if inviteKey.isUsed {
            return .failure(.usedInviteKey)
        }
        
        return .success(())
    }
    
    func useInviteKey(_ key: String, userId: String, userName: String, userEmail: String) {
        if var inviteKey = validInviteKeys[key.uppercased()] {
            if inviteKey.maxUses > 1 {
                inviteKey.currentUses += 1
                if inviteKey.currentUses >= inviteKey.maxUses {
                    inviteKey.isUsed = true
                }
            } else {
                inviteKey.isUsed = true
                inviteKey.usedBy = userId
                inviteKey.usedByName = userName
                inviteKey.usedByEmail = userEmail
                inviteKey.usedAt = Date()
            }
            validInviteKeys[key.uppercased()] = inviteKey
            saveInviteKeys()
        }
    }
    
    func getAllInviteKeys() -> [InviteKey] {
        return Array(validInviteKeys.values).sorted { $0.createdAt > $1.createdAt }
    }
    
    func createInviteKey(key: String, maxUses: Int, expiresAt: Date?) -> Result<Void, AppError> {
        let upperKey = key.uppercased()
        guard validInviteKeys[upperKey] == nil else {
            return .failure(.duplicateInviteKey)
        }
        
        let validation = Validator.validateInviteKey(key)
        guard validation.isValid else {
            return .failure(.validationFailed(validation.errorMessage ?? "Invalid"))
        }
        
        let newKey = InviteKey(
            id: UUID().uuidString,
            key: upperKey,
            createdBy: currentUser?.id ?? "admin",
            createdAt: Date(),
            isUsed: false,
            expiresAt: expiresAt,
            maxUses: maxUses,
            currentUses: 0
        )
        
        validInviteKeys[upperKey] = newKey
        saveInviteKeys()
        Logger.info("Invite key created: \(upperKey)")
        return .success(())
    }
    
    func deleteInviteKey(key: String) {
        validInviteKeys.removeValue(forKey: key.uppercased())
        saveInviteKeys()
    }
}

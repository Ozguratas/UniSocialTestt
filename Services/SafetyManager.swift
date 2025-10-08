import Foundation
import Combine
import UIKit
import CoreLocation    // ✅ EKLENDI

class SafetyManager: ObservableObject {
    static let shared = SafetyManager()
    
    @Published var activeSafetyCheck: SafetyCheck?
    @Published var safetyCheckHistory: [SafetyCheck] = []
    @Published var womenOnlyModeEnabled = false
    @Published var trustedContactsEnabled = true
    
    private var checkTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadSafetySettings()
        setupObservers()
    }
    
    // MARK: - Safety Check System
    
    func startSafetyCheck(for route: Route, estimatedDuration: Int) {
        let check = SafetyCheck(
            id: UUID().uuidString,
            routeId: route.id,
            userId: LocalStorageManager.shared.loadUserSession()?.id ?? "",
            startTime: Date(),
            estimatedEndTime: Date().addingTimeInterval(TimeInterval(estimatedDuration * 60)),
            status: .active
        )
        
        activeSafetyCheck = check
        safetyCheckHistory.append(check)
        saveSafetyCheckHistory()
        
        startPeriodicChecks(duration: estimatedDuration)
        
        LocationManager.shared.startRouteTracking(expectedRoute: [
            CLLocationCoordinate2D(latitude: route.startLatitude, longitude: route.startLongitude),
            CLLocationCoordinate2D(latitude: route.endLatitude, longitude: route.endLongitude)
        ])
        
        Logger.info("Safety check started for route: \(route.id)")
    }
    
    func completeSafetyCheck(safely: Bool = true) {
        guard var check = activeSafetyCheck else { return }
        
        check.status = safely ? .completed : .emergency
        check.endTime = Date()
        
        if let index = safetyCheckHistory.firstIndex(where: { $0.id == check.id }) {
            safetyCheckHistory[index] = check
        }
        
        activeSafetyCheck = nil
        stopPeriodicChecks()
        LocationManager.shared.stopTracking()
        
        if safely && trustedContactsEnabled {
            sendSafeArrivalNotifications()
        }
        
        saveSafetyCheckHistory()
        Logger.info("Safety check completed: \(safely ? "Safe" : "Emergency")")
    }
    
    private func startPeriodicChecks(duration: Int) {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.performPeriodicCheck()
        }
    }
    
    private func stopPeriodicChecks() {
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    private func performPeriodicCheck() {
        guard var check = activeSafetyCheck else { return }
        
        if Date() > check.estimatedEndTime.addingTimeInterval(600) {
            check.status = .delayed
            activeSafetyCheck = check
            sendDelayAlert()
        }
        
        if LocationManager.shared.isDeviatingFromRoute {
            sendRouteDeviationAlert()
        }
    }
    
    // MARK: - Women Only Mode
    
    func toggleWomenOnlyMode(_ enabled: Bool) {
        womenOnlyModeEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "womenOnlyMode")
        Logger.info("Women only mode: \(enabled)")
    }
    
    func canJoinRoute(_ route: Route, currentUser: User) -> (Bool, String?) {
        if womenOnlyModeEnabled && currentUser.gender == "Kadın" {
            if route.driverGender != "Kadın" {
                return (false, "Kadın-kadın yolculuk modu aktif")
            }
        }
        return (true, nil)
    }
    
    // MARK: - Trusted Contacts
    
    func shareTripWithContacts(route: Route) {
        let contacts = EmergencyManager.shared.emergencyContacts
        
        guard let locationURL = LocationManager.shared.getLocationShareURL()?.absoluteString else {
            return
        }
        
        let message = """
        🚗 UniSocial Yolculuk Bildirimi
        
        \(route.startLocation) → \(route.endLocation)
        Kalkış: \(route.departureTime.formatted(date: .abbreviated, time: .shortened))
        
        Konumumu takip et: \(locationURL)
        
        Güvenli geldim bildirimi alacaksınız.
        """
        
        for contact in contacts where contact.isPrimary {
            if contact.notifyViaSMS {
                EmergencyManager.shared.sendSMS(to: contact.phoneNumber, message: message)
            }
        }
    }
    
    private func sendSafeArrivalNotifications() {
        let contacts = EmergencyManager.shared.emergencyContacts.filter { $0.isPrimary }
        let message = "✅ Güvenli Geldim!\n\nUniSocial yolculuğum tamamlandı. Teşekkürler!"
        
        for contact in contacts {
            if contact.notifyViaSMS {
                EmergencyManager.shared.sendSMS(to: contact.phoneNumber, message: message)
            }
        }
    }
    
    private func sendDelayAlert() {
        let contacts = EmergencyManager.shared.emergencyContacts.filter { $0.isPrimary }
        let message = "⚠️ Yolculuk Gecikmesi\n\nUniSocial yolculuğum beklenenden uzun sürüyor. Takip etmeye devam edin."
        
        for contact in contacts {
            if contact.notifyViaSMS {
                EmergencyManager.shared.sendSMS(to: contact.phoneNumber, message: message)
            }
        }
    }
    
    private func sendRouteDeviationAlert() {
        let contacts = EmergencyManager.shared.emergencyContacts.filter { $0.isPrimary }
        
        guard let locationURL = LocationManager.shared.getLocationShareURL()?.absoluteString else {
            return
        }
        
        let message = """
        ⚠️ Rota Değişikliği
        
        UniSocial yolculuğum beklenenden farklı bir rotada ilerliyor.
        
        Güncel konum: \(locationURL)
        """
        
        for contact in contacts {
            if contact.notifyViaSMS {
                EmergencyManager.shared.sendSMS(to: contact.phoneNumber, message: message)
            }
        }
    }
    
    // MARK: - Verification
    
    func verifyPhoneNumber(_ phoneNumber: String, completion: @escaping (Bool) -> Void) {
        let code = String(format: "%06d", Int.random(in: 0...999999))
        let message = "UniSocial doğrulama kodunuz: \(code)"
        
        EmergencyManager.shared.sendSMS(to: phoneNumber, message: message)
        
        UserDefaults.standard.set(code, forKey: "verificationCode_\(phoneNumber)")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "verificationTime_\(phoneNumber)")
        
        Logger.info("Verification code sent to: \(phoneNumber)")
        completion(true)
    }
    
    func confirmVerificationCode(_ phoneNumber: String, code: String) -> Bool {
        guard let storedCode = UserDefaults.standard.string(forKey: "verificationCode_\(phoneNumber)") else {
            return false
        }
        
        let timestamp = UserDefaults.standard.double(forKey: "verificationTime_\(phoneNumber)")
        
        // ✅ FIXED: Check if timestamp exists
        guard timestamp > 0 else {
            return false
        }
        
        let elapsed = Date().timeIntervalSince1970 - timestamp
        guard elapsed < 300 else {
            Logger.error("Verification code expired")
            return false
        }
        
        let isValid = storedCode == code
        
        if isValid {
            UserDefaults.standard.removeObject(forKey: "verificationCode_\(phoneNumber)")
            UserDefaults.standard.removeObject(forKey: "verificationTime_\(phoneNumber)")
            UserDefaults.standard.set(true, forKey: "phoneVerified_\(phoneNumber)")
            Logger.info("Phone number verified: \(phoneNumber)")
        }
        
        return isValid
    }
    
    func isPhoneVerified(_ phoneNumber: String) -> Bool {
        return UserDefaults.standard.bool(forKey: "phoneVerified_\(phoneNumber)")
    }
    
    // MARK: - Profile Photo Verification
    
    func requestPhotoVerification() {
        Logger.info("Photo verification requested")
    }
    
    // MARK: - Persistence
    
    private func loadSafetySettings() {
        womenOnlyModeEnabled = UserDefaults.standard.bool(forKey: "womenOnlyMode")
        trustedContactsEnabled = UserDefaults.standard.bool(forKey: "trustedContactsEnabled")
        
        if let data = UserDefaults.standard.data(forKey: "safetyCheckHistory"),
           let history = try? JSONDecoder().decode([SafetyCheck].self, from: data) {
            safetyCheckHistory = history
        }
    }
    
    private func saveSafetyCheckHistory() {
        if let data = try? JSONEncoder().encode(safetyCheckHistory) {
            UserDefaults.standard.set(data, forKey: "safetyCheckHistory")
        }
    }
    
    // MARK: - Observers
    
    private func setupObservers() {
        NotificationCenter.default.publisher(for: NSNotification.Name("RouteDeviationDetected"))
            .sink { [weak self] _ in
                self?.sendRouteDeviationAlert()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Safety Check Model

struct SafetyCheck: Identifiable, Codable {
    let id: String
    let routeId: String
    let userId: String
    let startTime: Date
    let estimatedEndTime: Date
    var endTime: Date?
    var status: SafetyCheckStatus
}

enum SafetyCheckStatus: String, Codable {
    case active = "Aktif"
    case completed = "Tamamlandı"
    case delayed = "Gecikmeli"
    case emergency = "Acil Durum"
}

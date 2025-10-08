import Foundation
import UIKit
import MessageUI
import Combine
import CoreLocation      // ✅ EKLENDI
import AudioToolbox      // ✅ EKLENDI

class EmergencyManager: NSObject, ObservableObject {
    static let shared = EmergencyManager()
    
    @Published var isEmergencyActive = false
    @Published var emergencyStartTime: Date?
    @Published var emergencyContacts: [EmergencyContact] = []
    @Published var lastEmergencyAlert: Date?
    
    private let emergencyNumber = "155" // Polis
    private let ambulanceNumber = "112"
    
    private override init() {
        super.init()
        loadEmergencyContacts()
    }
    
    // MARK: - Emergency Activation
    
    func activateEmergency(reason: EmergencyReason = .general) {
        isEmergencyActive = true
        emergencyStartTime = Date()
        lastEmergencyAlert = Date()
        
        Logger.error("🚨 EMERGENCY ACTIVATED: \(reason.rawValue)")
        
        // 1. Location tracking başlat
        LocationManager.shared.startTracking()
        
        // 2. Acil kişilere bildirim gönder
        notifyEmergencyContacts(reason: reason)
        
        // 3. Local notification göster
        sendLocalNotification(reason: reason)
        
        // 4. Route tracking varsa admin'e bildir
        notifyAdminIfRouteActive()
        
        // 5. Vibration & Sound
        triggerEmergencyAlert()
        
        // 6. Safety log kaydet
        logEmergencyEvent(reason: reason)
    }
    
    func deactivateEmergency() {
        isEmergencyActive = false
        emergencyStartTime = nil
        
        Logger.info("Emergency deactivated")
        
        // "Güvenli geldim" mesajı gönder
        sendSafeArrivalMessage()
    }
    
    // MARK: - Emergency Contacts
    
    func addEmergencyContact(_ contact: EmergencyContact) {
        emergencyContacts.append(contact)
        saveEmergencyContacts()
        Logger.info("Emergency contact added: \(contact.name)")
    }
    
    func removeEmergencyContact(_ contact: EmergencyContact) {
        emergencyContacts.removeAll { $0.id == contact.id }
        saveEmergencyContacts()
    }
    
    private func loadEmergencyContacts() {
        if let data = UserDefaults.standard.data(forKey: "emergencyContacts"),
           let contacts = try? JSONDecoder().decode([EmergencyContact].self, from: data) {
            self.emergencyContacts = contacts
        }
    }
    
    private func saveEmergencyContacts() {
        if let data = try? JSONEncoder().encode(emergencyContacts) {
            UserDefaults.standard.set(data, forKey: "emergencyContacts")
        }
    }
    
    // MARK: - Notifications
    
    private func notifyEmergencyContacts(reason: EmergencyReason) {
        let message = LocationManager.shared.getLocationShareMessage()
        
        for contact in emergencyContacts {
            if contact.notifyViaSMS {
                sendSMS(to: contact.phoneNumber, message: message)
            }
            
            if contact.notifyViaWhatsApp {
                sendWhatsAppMessage(to: contact.phoneNumber, message: message)
            }
        }
    }
    
    // ✅ CHANGED: private -> internal
    func sendSMS(to phoneNumber: String, message: String) {
        guard let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }
        
        guard let url = URL(string: "sms:\(phoneNumber)&body=\(encodedMessage)") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func sendWhatsAppMessage(to phoneNumber: String, message: String) {
        let cleanNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "+", with: "")
        
        guard let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://wa.me/\(cleanNumber)?text=\(encodedMessage)") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func sendLocalNotification(reason: EmergencyReason) {
        let content = UNMutableNotificationContent()
        content.title = "🚨 Acil Durum Aktif"
        content.body = "Acil kişilerinize bildirim gönderildi. \(reason.description)"
        content.sound = .defaultCritical
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func sendSafeArrivalMessage() {
        let message = "✅ Güvenli Geldim - UniSocial Yolculuk\n\nAcil durum iptal edildi. Herşey yolunda!"
        
        for contact in emergencyContacts {
            if contact.notifyViaSMS {
                sendSMS(to: contact.phoneNumber, message: message)
            }
        }
    }
    
    // MARK: - Call Emergency Services
    
    func callPolice() {
        callEmergencyNumber(emergencyNumber)
    }
    
    func callAmbulance() {
        callEmergencyNumber(ambulanceNumber)
    }
    
    private func callEmergencyNumber(_ number: String) {
        guard let url = URL(string: "tel://\(number)") else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Helpers
    
    private func triggerEmergencyAlert() {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        // Vibration pattern
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        // Play alert sound
        AudioServicesPlaySystemSound(1005) // SMS received sound
    }
    
    private func notifyAdminIfRouteActive() {
        Logger.error("Admin notification: Emergency during active route")
    }
    
    private func logEmergencyEvent(reason: EmergencyReason) {
        let log = EmergencyLog(
            id: UUID().uuidString,
            userId: LocalStorageManager.shared.loadUserSession()?.id ?? "",
            reason: reason,
            location: LocationManager.shared.currentLocation,
            timestamp: Date()
        )
        
        var logs = loadEmergencyLogs()
        logs.append(log)
        saveEmergencyLogs(logs)
    }
    
    private func loadEmergencyLogs() -> [EmergencyLog] {
        if let data = UserDefaults.standard.data(forKey: "emergencyLogs"),
           let logs = try? JSONDecoder().decode([EmergencyLog].self, from: data) {
            return logs
        }
        return []
    }
    
    private func saveEmergencyLogs(_ logs: [EmergencyLog]) {
        if let data = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(data, forKey: "emergencyLogs")
        }
    }
}

// MARK: - Supporting Types

struct EmergencyContact: Identifiable, Codable {
    let id: String
    var name: String
    var phoneNumber: String
    var relationship: String
    var notifyViaSMS: Bool
    var notifyViaWhatsApp: Bool
    var isPrimary: Bool
}

enum EmergencyReason: String, Codable {
    case general = "Genel Acil Durum"
    case unsafeDriver = "Güvensiz Sürücü"
    case harassment = "Taciz"
    case accident = "Kaza"
    case routeDeviation = "Rota Sapması"
    case uncomfortable = "Rahatsız Hissediyorum"
    
    var description: String {
        return self.rawValue
    }
}

struct EmergencyLog: Identifiable, Codable {
    let id: String
    let userId: String
    let reason: EmergencyReason
    let location: CLLocation?
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId, reason, timestamp
        case latitude, longitude
    }
    
    init(id: String, userId: String, reason: EmergencyReason, location: CLLocation?, timestamp: Date) {
        self.id = id
        self.userId = userId
        self.reason = reason
        self.location = location
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        reason = try container.decode(EmergencyReason.self, forKey: .reason)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        if let lat = try? container.decode(Double.self, forKey: .latitude),
           let lon = try? container.decode(Double.self, forKey: .longitude) {
            location = CLLocation(latitude: lat, longitude: lon)
        } else {
            location = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(reason, forKey: .reason)
        try container.encode(timestamp, forKey: .timestamp)
        
        if let location = location {
            try container.encode(location.coordinate.latitude, forKey: .latitude)
            try container.encode(location.coordinate.longitude, forKey: .longitude)
        }
    }
}

import Foundation
import SwiftUI
import Combine

class AchievementViewModel: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var userAchievements: [String] = []
    
    init() {
        loadAchievements()
    }
    
    private func loadAchievements() {
        let cached = LocalStorageManager.shared.loadCachedAchievements()
        if !cached.isEmpty {
            self.achievements = cached
        } else {
            createDefaultAchievements()
        }
    }
    
    private func createDefaultAchievements() {
        achievements = [
            // Sosyal Başarımlar
            Achievement(
                id: "first_friend",
                title: "İlk Arkadaş",
                description: "İlk arkadaşını ekle",
                category: .social,
                icon: "person.badge.plus",
                requiredValue: 1,
                isUnlocked: false,
                progress: 0
            ),
            Achievement(
                id: "social_butterfly",
                title: "Sosyal Kelebek",
                description: "10 arkadaş edin",
                category: .social,
                icon: "person.3.fill",
                requiredValue: 10,
                isUnlocked: false,
                progress: 0
            ),
            Achievement(
                id: "popular",
                title: "Popüler",
                description: "25 arkadaş edin",
                category: .social,
                icon: "star.fill",
                requiredValue: 25,
                isUnlocked: false,
                progress: 0
            ),
            
            // Yolculuk Başarımları
            Achievement(
                id: "first_ride",
                title: "İlk Yolculuk",
                description: "İlk güzergahını oluştur",
                category: .travel,
                icon: "car.fill",
                requiredValue: 1,
                isUnlocked: false,
                progress: 0
            ),
            Achievement(
                id: "frequent_driver",
                title: "Sık Sürücü",
                description: "5 güzergah oluştur",
                category: .travel,
                icon: "car.2.fill",
                requiredValue: 5,
                isUnlocked: false,
                progress: 0
            ),
            Achievement(
                id: "road_master",
                title: "Yol Ustası",
                description: "20 güzergah oluştur",
                category: .travel,
                icon: "map.fill",
                requiredValue: 20,
                isUnlocked: false,
                progress: 0
            ),
            
            // Etkinlik Başarımları
            Achievement(
                id: "first_event",
                title: "İlk Etkinlik",
                description: "İlk etkinliğini oluştur",
                category: .event,
                icon: "calendar.badge.plus",
                requiredValue: 1,
                isUnlocked: false,
                progress: 0
            ),
            Achievement(
                id: "event_organizer",
                title: "Etkinlik Organizatörü",
                description: "5 etkinlik düzenle",
                category: .event,
                icon: "calendar.circle.fill",
                requiredValue: 5,
                isUnlocked: false,
                progress: 0
            ),
            
            // Topluluk Başarımları
            Achievement(
                id: "five_star",
                title: "5 Yıldız",
                description: "10 tane 5 yıldızlı değerlendirme al",
                category: .community,
                icon: "star.circle.fill",
                requiredValue: 10,
                isUnlocked: false,
                progress: 0
            ),
            Achievement(
                id: "helpful",
                title: "Yardımsever",
                description: "20 yorum yap",
                category: .community,
                icon: "bubble.left.and.bubble.right.fill",
                requiredValue: 20,
                isUnlocked: false,
                progress: 0
            ),
            Achievement(
                id: "trusted",
                title: "Güvenilir",
                description: "4.5+ ortalama puan al",
                category: .community,
                icon: "checkmark.seal.fill",
                requiredValue: 1,
                isUnlocked: false,
                progress: 0
            )
        ]
        
        saveAchievements()
    }
    
    private func saveAchievements() {
        LocalStorageManager.shared.cacheAchievements(achievements)
    }
    
    func checkAndUnlockAchievement(id: String, currentValue: Int, userId: String) -> Achievement? {
        guard let index = achievements.firstIndex(where: { $0.id == id }),
              !achievements[index].isUnlocked,
              currentValue >= achievements[index].requiredValue else {
            return nil
        }
        
        achievements[index].isUnlocked = true
        achievements[index].unlockedAt = Date()
        saveAchievements()
        
        Logger.info("Achievement unlocked: \(achievements[index].title)")
        return achievements[index]
    }
    
    func getUnlockedAchievements() -> [Achievement] {
        return achievements.filter { $0.isUnlocked }
    }
    
    func getAchievements(by category: AchievementCategory) -> [Achievement] {
        return achievements.filter { $0.category == category }
    }
    
    func getProgress(for achievement: Achievement, currentValue: Int) -> Double {
        return min(Double(currentValue) / Double(achievement.requiredValue), 1.0)
    }
}

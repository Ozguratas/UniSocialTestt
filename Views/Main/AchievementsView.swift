import SwiftUI

// MARK: - AchievementView
struct AchievementView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedCategory: AchievementCategory?
    
    let sampleAchievements: [Achievement] = [
        Achievement(
            id: "ach1",
            title: "İlk Yolculuk",
            description: "İlk güzergahını tamamladın!",
            category: .travel,
            icon: "car.fill",
            requiredValue: 1,
            isUnlocked: true,
            unlockedAt: Date(),
            progress: 1
        ),
        Achievement(
            id: "ach2",
            title: "Yolcu Dostu",
            description: "10 yolculuk tamamla",
            category: .travel,
            icon: "star.fill",
            requiredValue: 10,
            isUnlocked: false,
            unlockedAt: nil,
            progress: 3
        ),
        Achievement(
            id: "ach3",
            title: "Sosyal Kelebek",
            description: "5 etkinliğe katıl",
            category: .social,
            icon: "person.3.fill",
            requiredValue: 5,
            isUnlocked: false,
            unlockedAt: nil,
            progress: 2
        ),
        Achievement(
            id: "ach4",
            title: "Forum Aktifi",
            description: "50 forum gönderisi paylaş",
            category: .community,
            icon: "bubble.left.and.bubble.right.fill",
            requiredValue: 50,
            isUnlocked: false,
            unlockedAt: nil,
            progress: 12
        ),
        Achievement(
            id: "ach5",
            title: "5 Yıldız",
            description: "5.0 ortalama puan al",
            category: .special,
            icon: "star.circle.fill",
            requiredValue: 1,
            isUnlocked: false,
            unlockedAt: nil,
            progress: 0
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryFilterChip(
                            category: nil,
                            title: "Tümü",
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }
                        
                        ForEach(AchievementCategory.allCases, id: \.self) { category in
                            CategoryFilterChip(
                                category: category,
                                title: category.rawValue,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                List(filteredAchievements) { achievement in
                    AchievementRow(achievement: achievement)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Başarılar")
        }
    }
    
    private var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return sampleAchievements.filter { $0.category == category }
        }
        return sampleAchievements
    }
}

// MARK: - Category Filter Chip
struct CategoryFilterChip: View {
    let category: AchievementCategory?
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Achievement Row
struct AchievementRow: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: achievement.icon)
                .font(.system(size: 40))
                .foregroundColor(achievement.isUnlocked ? .yellow : .gray)
                .frame(width: 60, height: 60)
                .background(achievement.isUnlocked ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(achievement.title)
                    .font(.headline)
                    .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !achievement.isUnlocked {
                    VStack(alignment: .leading, spacing: 4) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 4)
                                
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * progressPercentage, height: 4)
                            }
                        }
                        .frame(height: 4)
                        
                        Text("\(achievement.progress)/\(achievement.requiredValue)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else if let unlockedAt = achievement.unlockedAt {
                    Text("Açıldı: \(unlockedAt.timeAgoDisplay())")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
    }
    
    private var progressPercentage: CGFloat {
        CGFloat(achievement.progress) / CGFloat(achievement.requiredValue)
    }
}

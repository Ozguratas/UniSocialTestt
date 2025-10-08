import Foundation
import SwiftUI
import Combine

class ReviewViewModel: ObservableObject {
    @Published var reviews: [Review] = []
    @Published var isLoading = false
    
    init() {
        loadReviews()
        loadSampleData()
    }
    
    private func loadReviews() {
        let cached = LocalStorageManager.shared.loadCachedReviews()
        if !cached.isEmpty {
            self.reviews = cached
        }
    }
    
    private func loadSampleData() {
        if reviews.isEmpty {
            reviews = [
                Review(
                    id: "review1",
                    reviewerId: "user1",
                    reviewerName: "Ahmet Yılmaz",
                    reviewedUserId: "user2",
                    routeId: "route1",
                    rating: 4.5,
                    comment: "Çok iyi bir sürücü, zamanında geldi ve güvenli sürüş yaptı.",
                    categories: [
                        .punctuality: 5.0,
                        .communication: 4.5,
                        .cleanliness: 4.0,
                        .driving: 5.0,
                        .friendliness: 4.5
                    ],
                    createdAt: Date().addingTimeInterval(-86400)
                ),
                Review(
                    id: "review2",
                    reviewerId: "user3",
                    reviewerName: "Mehmet Kaya",
                    reviewedUserId: "user2",
                    routeId: "route2",
                    rating: 5.0,
                    comment: "Harika bir deneyimdi, kesinlikle tekrar yolculuk yapmak isterim.",
                    categories: [
                        .punctuality: 5.0,
                        .communication: 5.0,
                        .cleanliness: 5.0,
                        .driving: 5.0,
                        .friendliness: 5.0
                    ],
                    createdAt: Date().addingTimeInterval(-172800)
                ),
                Review(
                    id: "review3",
                    reviewerId: "user4",
                    reviewerName: "Zeynep Aydın",
                    reviewedUserId: "user2",
                    routeId: "route3",
                    rating: 4.0,
                    comment: "İyi bir yolculuktu, sadece araç biraz daha temiz olabilirdi.",
                    categories: [
                        .punctuality: 4.5,
                        .communication: 4.0,
                        .cleanliness: 3.0,
                        .driving: 4.5,
                        .friendliness: 4.0
                    ],
                    createdAt: Date().addingTimeInterval(-259200)
                )
            ]
            saveReviews()
        }
    }
    
    private func saveReviews() {
        LocalStorageManager.shared.cacheReviews(reviews)
    }
    
    func createReview(
        reviewerId: String,
        reviewerName: String,
        reviewedUserId: String,
        routeId: String?,
        rating: Double,
        comment: String,
        categories: [ReviewCategory: Double]
    ) {
        let newReview = Review(
            id: UUID().uuidString,
            reviewerId: reviewerId,
            reviewerName: reviewerName,
            reviewedUserId: reviewedUserId,
            routeId: routeId,
            rating: rating,
            comment: comment,
            categories: categories,
            createdAt: Date()
        )
        
        reviews.insert(newReview, at: 0)
        saveReviews()
        Logger.info("Review created for user: \(reviewedUserId)")
    }
    
    func getReviews(for userId: String) -> [Review] {
        return reviews.filter { $0.reviewedUserId == userId }.sorted { $0.createdAt > $1.createdAt }
    }
    
    func getAverageRating(for userId: String) -> Double {
        let userReviews = getReviews(for: userId)
        guard !userReviews.isEmpty else { return 0.0 }
        let sum = userReviews.reduce(0.0) { $0 + $1.rating }
        return sum / Double(userReviews.count)
    }
    
    func hasReviewed(reviewerId: String, reviewedUserId: String, routeId: String?) -> Bool {
        return reviews.contains { review in
            review.reviewerId == reviewerId &&
            review.reviewedUserId == reviewedUserId &&
            review.routeId == routeId
        }
    }
    
    func getAverageCategoryRatings(for userId: String) -> ReviewCategories {
        let userReviews = getReviews(for: userId)
        guard !userReviews.isEmpty else {
            return ReviewCategories(safety: 0, punctuality: 0, communication: 0, cleanliness: 0)
        }
        
        var safetyTotal = 0.0
        var punctualityTotal = 0.0
        var communicationTotal = 0.0
        var cleanlinessTotal = 0.0
        
        for review in userReviews {
            safetyTotal += review.categories[.driving] ?? 0
            punctualityTotal += review.categories[.punctuality] ?? 0
            communicationTotal += review.categories[.communication] ?? 0
            cleanlinessTotal += review.categories[.cleanliness] ?? 0
        }
        
        let count = Double(userReviews.count)
        return ReviewCategories(
            safety: safetyTotal / count,
            punctuality: punctualityTotal / count,
            communication: communicationTotal / count,
            cleanliness: cleanlinessTotal / count
        )
    }
}

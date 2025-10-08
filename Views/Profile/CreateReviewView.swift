import SwiftUI
import Combine

// MARK: - CreateReviewView
struct CreateReviewView: View {
    @EnvironmentObject var reviewViewModel: ReviewViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    let reviewedUserId: String
    let reviewedUserName: String
    let routeId: String?
    
    @State private var overallRating: Double = 5.0
    @State private var safetyRating: Double = 5.0
    @State private var punctualityRating: Double = 5.0
    @State private var communicationRating: Double = 5.0
    @State private var cleanlinessRating: Double = 5.0
    @State private var comment = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Genel Değerlendirme")) {
                    VStack {
                        Text(String(format: "%.1f", overallRating))
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.orange)
                        
                        StarRatingView(rating: $overallRating)
                            .frame(height: 40)
                        
                        Text("\(reviewedUserName) için değerlendirmeniz")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                
                Section(header: Text("Detaylı Değerlendirme")) {
                    RatingRow(title: "Güvenlik", icon: "shield.fill", rating: $safetyRating)
                    RatingRow(title: "Dakiklik", icon: "clock.fill", rating: $punctualityRating)
                    RatingRow(title: "İletişim", icon: "message.fill", rating: $communicationRating)
                    RatingRow(title: "Temizlik", icon: "sparkles", rating: $cleanlinessRating)
                }
                
                Section(header: Text("Yorum (Opsiyonel)")) {
                    TextEditor(text: $comment)
                        .frame(height: 100)
                }
                
                Section {
                    Button(action: submitReview) {
                        HStack {
                            Spacer()
                            Text("Değerlendirmeyi Gönder")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Değerlendirme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
            .alert("Bilgi", isPresented: $showAlert) {
                Button("Tamam") {
                    if alertMessage.contains("başarıyla") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func submitReview() {
        guard let currentUser = authViewModel.currentUser else {
            alertMessage = "❌ Kullanıcı bilgisi bulunamadı"
            showAlert = true
            return
        }
        
        if reviewViewModel.hasReviewed(
            reviewerId: currentUser.id,
            reviewedUserId: reviewedUserId,
            routeId: routeId
        ) {
            alertMessage = "⚠️ Bu kullanıcıyı zaten değerlendirdiniz"
            showAlert = true
            return
        }
        
        let categories: [ReviewCategory: Double] = [
            .driving: safetyRating,
            .punctuality: punctualityRating,
            .communication: communicationRating,
            .cleanliness: cleanlinessRating,
            .friendliness: overallRating
        ]
        
        reviewViewModel.createReview(
            reviewerId: currentUser.id,
            reviewerName: currentUser.name,
            reviewedUserId: reviewedUserId,
            routeId: routeId,
            rating: overallRating,
            comment: comment,
            categories: categories
        )
        
        alertMessage = "✅ Değerlendirme başarıyla gönderildi!"
        showAlert = true
    }
}

// MARK: - Star Rating View
struct StarRatingView: View {
    @Binding var rating: Double
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= Int(rating.rounded()) ? "star.fill" : "star")
                    .font(.title2)
                    .foregroundColor(.orange)
                    .onTapGesture {
                        rating = Double(index)
                    }
            }
        }
    }
}

// MARK: - Rating Row
struct RatingRow: View {
    let title: String
    let icon: String
    @Binding var rating: Double
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.1f", rating))
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            
            Slider(value: $rating, in: 1...5, step: 0.5)
                .accentColor(.orange)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - User Reviews View
struct UserReviewsView: View {
    @EnvironmentObject var reviewViewModel: ReviewViewModel
    let userId: String
    let userName: String
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        Text(String(format: "%.1f", reviewViewModel.getAverageRating(for: userId)))
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(.orange)
                        
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { index in
                                Image(systemName: index <= Int(reviewViewModel.getAverageRating(for: userId).rounded()) ? "star.fill" : "star")
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Text("\(reviewViewModel.getReviews(for: userId).count) değerlendirme")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    let categories = reviewViewModel.getAverageCategoryRatings(for: userId)
                    
                    VStack(spacing: 12) {
                        CategoryRatingBar(title: "Güvenlik", icon: "shield.fill", rating: categories.safety)
                        CategoryRatingBar(title: "Dakiklik", icon: "clock.fill", rating: categories.punctuality)
                        CategoryRatingBar(title: "İletişim", icon: "message.fill", rating: categories.communication)
                        CategoryRatingBar(title: "Temizlik", icon: "sparkles", rating: categories.cleanliness)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Değerlendirmeler")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(reviewViewModel.getReviews(for: userId)) { review in
                            ReviewCard(review: review)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("\(userName) Değerlendirmeleri")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CategoryRatingBar: View {
    let title: String
    let icon: String
    let rating: Double
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .frame(width: 80, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: geometry.size.width * (rating / 5.0))
                }
                .frame(height: 8)
                .cornerRadius(4)
            }
            
            Text(String(format: "%.1f", rating))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct ReviewCard: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.reviewerName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(review.createdAt.timeAgoDisplay())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(String(format: "%.1f", review.rating))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            
            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

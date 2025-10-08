import Foundation
import CoreGraphics

enum AppConstants {
    enum ValidationRules {
        static let minPasswordLength = 6
        static let minInviteKeyLength = 4
        static let maxBioLength = 500
    }
    
    enum TimeIntervals {
        static let oneHour: TimeInterval = 3_600
        static let oneDay: TimeInterval = 86_400
        static let oneWeek: TimeInterval = 604_800
    }
    
    enum Limits {
        static let maxSeatsPerRoute = 4
        static let maxInterests = 10
    }
    
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let buttonHeight: CGFloat = 50
        static let padding: CGFloat = 16
    }
}

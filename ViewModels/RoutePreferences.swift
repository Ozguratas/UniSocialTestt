import Foundation

struct RoutePreferences: Codable, Equatable {
    var smokingAllowed: Bool
    var petsAllowed: Bool
    var musicPreference: String
    var chatLevel: String
    var genderPreference: String
    var luggageSpace: String
    
    init(
        smokingAllowed: Bool = false,
        petsAllowed: Bool = false,
        musicPreference: String = "Fark etmez",
        chatLevel: String = "Orta",
        genderPreference: String = "Hepsi",
        luggageSpace: String = "Orta"
    ) {
        self.smokingAllowed = smokingAllowed
        self.petsAllowed = petsAllowed
        self.musicPreference = musicPreference
        self.chatLevel = chatLevel
        self.genderPreference = genderPreference
        self.luggageSpace = luggageSpace
    }
}

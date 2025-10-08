import Foundation
import SwiftUI
import Combine

class EventViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    
    init() {
        loadEventsFromCache()
        loadSampleData()
    }
    
    private func loadEventsFromCache() {
        let cached = LocalStorageManager.shared.loadCachedEvents()
        if !cached.isEmpty {
            self.events = cached
        }
    }
    
    func loadSampleData() {
        if events.isEmpty {
            events = [
                Event(
                    id: "1",
                    creatorId: "user1",
                    creatorName: "Mehmet Demir",
                    title: "Kahve & Sohbet",
                    description: "Kampüste kahve içelim",
                    location: "Starbucks Maslak",
                    eventTime: Date().addingTimeInterval(AppConstants.TimeIntervals.oneDay),
                    participants: ["user1"],
                    maxParticipants: 8,
                    category: .social,
                    requirements: []
                )
            ]
            LocalStorageManager.shared.cacheEvents(events)
        }
    }
    
    func createEvent(_ event: Event) {
        events.insert(event, at: 0)
        LocalStorageManager.shared.cacheEvents(events)
        Logger.info("Event created: \(event.title)")
    }
    
    func createEvent(
        organizerId: String,
        organizerName: String,
        title: String,
        description: String,
        category: EventCategory,
        date: Date,
        location: String,
        maxParticipants: Int,
        requirements: [String]
    ) {
        let newEvent = Event(
            creatorId: organizerId,
            creatorName: organizerName,
            title: title,
            description: description,
            location: location,
            eventTime: date,
            participants: [organizerId],
            maxParticipants: maxParticipants,
            category: category,
            requirements: requirements
        )
        
        events.insert(newEvent, at: 0)
        LocalStorageManager.shared.cacheEvents(events)
        Logger.info("Event created: \(title)")
    }
    
    func joinEvent(eventId: String, userId: String) {
        guard let index = events.firstIndex(where: { $0.id == eventId }) else { return }
        
        if !events[index].participants.contains(userId) &&
           events[index].participants.count < events[index].maxParticipants {
            events[index].participants.append(userId)
            LocalStorageManager.shared.cacheEvents(events)
            Logger.info("User \(userId) joined event: \(eventId)")
        }
    }
    
    func leaveEvent(eventId: String, userId: String) {
        guard let index = events.firstIndex(where: { $0.id == eventId }) else { return }
        
        events[index].participants.removeAll { $0 == userId }
        LocalStorageManager.shared.cacheEvents(events)
        Logger.info("User \(userId) left event: \(eventId)")
    }
    
    func deleteEvent(eventId: String) {
        events.removeAll { $0.id == eventId }
        LocalStorageManager.shared.cacheEvents(events)
        Logger.info("Event deleted: \(eventId)")
    }
    
    func getEvent(by id: String) -> Event? {
        return events.first { $0.id == id }
    }
    
    func getEventsByCategory(_ category: EventCategory) -> [Event] {
        return events.filter { $0.category == category }
    }
    
    func getUpcomingEvents() -> [Event] {
        return events.filter { $0.eventTime > Date() }
            .sorted { $0.eventTime < $1.eventTime }
    }
    
    func getParticipatingEvents(userId: String) -> [Event] {
        return events.filter { $0.participants.contains(userId) }
    }
    
    func getCreatedEvents(userId: String) -> [Event] {
        return events.filter { $0.creatorId == userId }
    }
}

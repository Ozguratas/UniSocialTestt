import SwiftUI

struct EnhancedEventsView: View {
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingCreateEvent = false
    @State private var selectedCategory: EventCategory?
    
    var todayEvents: [Event] {
        eventViewModel.events.filter { event in
            Calendar.current.isDateInToday(event.eventTime)
        }
    }
    
    var upcomingEvents: [Event] {
        eventViewModel.events.filter { event in
            event.eventTime > Date() && !Calendar.current.isDateInToday(event.eventTime)
        }.sorted { $0.eventTime < $1.eventTime }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Bugünkü etkinlikler (öne çıkan)
                if !todayEvents.isEmpty {
                    todayEventsSection
                }
                
                // Kategori filtresi
                categoryFilter
                
                // Yaklaşan etkinlikler
                upcomingEventsSection
            }
            .padding()
        }
        .navigationTitle("Etkinlikler 🎉")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCreateEvent = true }) {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingCreateEvent) {
            CreateEventView()
                .environmentObject(eventViewModel)
                .environmentObject(authViewModel)
        }
    }
    
    private var todayEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Bugün")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            ForEach(todayEvents) { event in
                HighlightedEventCard(event: event)
                    .environmentObject(eventViewModel)
                    .environmentObject(authViewModel)
            }
        }
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryButton(
                    title: "Tümü",
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                ForEach(EventCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
        }
    }
    
    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Yaklaşan Etkinlikler")
                .font(.headline)
            
            let filtered = selectedCategory == nil ? upcomingEvents : upcomingEvents.filter { $0.category == selectedCategory }
            
            ForEach(filtered) { event in
                EventCard(event: event)
                    .environmentObject(eventViewModel)
                    .environmentObject(authViewModel)
            }
        }
    }
}

struct HighlightedEventCard: View {
    let event: Event
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showDetail = false
    
    var body: some View {
        Button(action: { showDetail = true }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: event.category.icon)
                        .font(.title)
                        .foregroundColor(event.category.color)
                        .frame(width: 60, height: 60)
                        .background(event.category.color.opacity(0.2))
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(event.eventTime.formatted(date: .omitted, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                Text(event.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label(event.location, systemImage: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("\(event.participants.count)/\(event.maxParticipants)")
                            .font(.caption)
                    }
                    .foregroundColor(event.participants.count >= event.maxParticipants ? .red : .green)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [event.category.color.opacity(0.1), event.category.color.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(event.category.color.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            EventDetailView(event: event)
                .environmentObject(eventViewModel)
                .environmentObject(authViewModel)
        }
    }
}

// MARK: - Supporting Components

struct CategoryButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct EventCard: View {
    let event: Event
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showDetail = false
    
    var body: some View {
        Button(action: { showDetail = true }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: event.category.icon)
                        .font(.title2)
                        .foregroundColor(event.category.color)
                        .frame(width: 50, height: 50)
                        .background(event.category.color.opacity(0.1))
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(event.organizerName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(event.date.formatted(.dateTime.month().day()))
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text(event.date.formatted(.dateTime.hour().minute()))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(event.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label(event.location, systemImage: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("\(event.participants.count)/\(event.maxParticipants)")
                            .font(.caption)
                    }
                    .foregroundColor(event.participants.count >= event.maxParticipants ? .red : .green)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .sheet(isPresented: $showDetail) {
            EventDetailView(event: event)
                .environmentObject(eventViewModel)
                .environmentObject(authViewModel)
        }
    }
}

struct EventDetailView: View {
    let event: Event
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ZStack {
                        Rectangle()
                            .fill(event.category.color.opacity(0.2))
                            .frame(height: 200)
                        
                        VStack {
                            Image(systemName: event.category.icon)
                                .font(.system(size: 60))
                                .foregroundColor(event.category.color)
                            
                            Text(event.category.rawValue)
                                .font(.headline)
                                .foregroundColor(event.category.color)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text(event.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                            Text("Organizatör: \(event.organizerName)")
                                .font(.subheadline)
                        }
                        
                        Divider()
                        
                        EventInfoRow(icon: "calendar", title: "Tarih", value: event.date.formatted(date: .long, time: .omitted))
                        EventInfoRow(icon: "clock", title: "Saat", value: event.date.formatted(date: .omitted, time: .shortened))
                        EventInfoRow(icon: "mappin.circle.fill", title: "Konum", value: event.location)
                        EventInfoRow(icon: "person.2.fill", title: "Katılımcılar", value: "\(event.participants.count)/\(event.maxParticipants)")
                        
                        Divider()
                        
                        Text("Açıklama")
                            .font(.headline)
                        
                        Text(event.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        if !event.requirements.isEmpty {
                            Divider()
                            
                            Text("Gereksinimler")
                                .font(.headline)
                            
                            ForEach(event.requirements, id: \.self) { requirement in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(requirement)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                    .padding()
                    
                    if let userId = authViewModel.currentUser?.id {
                        if event.participants.contains(userId) {
                            Button(action: {
                                eventViewModel.leaveEvent(eventId: event.id, userId: userId)
                                dismiss()
                            }) {
                                Text("Etkinlikten Ayrıl")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        } else if event.participants.count < event.maxParticipants {
                            Button(action: {
                                eventViewModel.joinEvent(eventId: event.id, userId: userId)
                                dismiss()
                            }) {
                                Text("Etkinliğe Katıl")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        } else {
                            Text("Etkinlik Dolu")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray)
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

struct EventInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
            }
        }
    }
}

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var routeViewModel: RouteViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var safetyManager = SafetyManager.shared
    
    @State private var showingCreateRoute = false
    @State private var showingFilters = false
    @State private var selectedRoute: Route?
    @State private var activeRoute: Route?
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List(routeViewModel.filteredRoutes) { route in
                Button(action: {
                    selectedRoute = route
                }) {
                    RouteRowView(route: route, safetyManager: safetyManager, currentUser: authViewModel.currentUser)
                }
            }
            .navigationTitle("Güzergahlar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
            .overlay {
                if routeViewModel.filteredRoutes.isEmpty {
                    emptyStateView
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView()
                    .environmentObject(routeViewModel)
            }
            .sheet(item: $selectedRoute) { route in
                RouteDetailSheet(
                    route: route,
                    safetyManager: safetyManager,
                    currentUser: authViewModel.currentUser,
                    activeRoute: $activeRoute
                )
            }
            
            Button(action: { showingCreateRoute = true }) {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showingCreateRoute) {
            CreateRouteView()
                .environmentObject(routeViewModel)
                .environmentObject(authViewModel)
        }
        .fullScreenCover(item: $activeRoute) { route in
            ActiveRideTrackingView(route: route)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "car.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("Henüz güzergah yok")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("İlk güzergahı sen oluştur!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - RouteRowView
struct RouteRowView: View {
    let route: Route
    let safetyManager: SafetyManager
    let currentUser: User?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(route.driverName)
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", route.driverRating))
                                .font(.caption)
                        }
                        
                        if route.driverRating >= 4.5 {
                            HStack(spacing: 2) {
                                Image(systemName: "shield.checkered")
                                    .font(.caption)
                                Text("Güvenli")
                                    .font(.caption2)
                            }
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                        }
                        
                        if route.driverGender != "Belirtilmemiş" {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 2) {
                                Image(systemName: route.driverGender == "Kadın" ? "person.fill" : "person")
                                    .font(.caption2)
                                Text(route.driverGender)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(route.availableSeats) koltuk")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(route.availableSeats > 0 ? Color.green : Color.red)
                        .cornerRadius(8)
                    
                    if route.isRecurring {
                        Text("🔁 Tekrarlı")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Divider()
            
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.green)
                    Text(route.startLocation)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.red)
                    Text(route.endLocation)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            Divider()
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text(route.departureTime.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .environment(\.locale, Locale(identifier: "tr_TR"))
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "car")
                        .foregroundColor(.gray)
                        .font(.caption)
                    Text(route.vehicleInfo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let user = currentUser {
                let (canJoin, reason) = safetyManager.canJoinRoute(route, currentUser: user)
                if !canJoin, let reason = reason {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text(reason)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - RouteDetailSheet
struct RouteDetailSheet: View {
    let route: Route
    let safetyManager: SafetyManager
    let currentUser: User?
    @Binding var activeRoute: Route?
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Güzergah Detayları")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        RouteInfoCard(route: route)
                    }
                    .padding()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Güvenlik Özellikleri")
                            .font(.headline)
                        
                        SafetyFeatureRow(icon: "location.fill", title: "GPS Takip", detail: "Yolculuk boyunca konum takibi")
                        SafetyFeatureRow(icon: "person.2.fill", title: "Acil Kişiler", detail: "Otomatik bildirim")
                        SafetyFeatureRow(icon: "shield.checkered", title: "Güvenli Sürücü", detail: "\(String(format: "%.1f", route.driverRating)) puan")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    if let user = currentUser {
                        let (canJoin, reason) = safetyManager.canJoinRoute(route, currentUser: user)
                        
                        if canJoin {
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                
                                print("🚗 Güzergaha katılınıyor: \(route.startLocation) → \(route.endLocation)")
                                
                                activeRoute = route
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Güzergaha Katıl")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text(reason ?? "Bu güzergaha katılamazsınız")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                }
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - RouteInfoCard
struct RouteInfoCard: View {
    let route: Route
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                Text(route.startLocation)
                    .font(.headline)
            }
            
            Image(systemName: "arrow.down")
                .foregroundColor(.gray)
                .padding(.leading, 4)
            
            HStack {
                Image(systemName: "circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
                Text(route.endLocation)
                    .font(.headline)
            }
            
            Divider()
            
            HStack {
                Label(route.departureTime.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                    .font(.subheadline)
                Spacer()
                Label("\(route.estimatedDuration) dk", systemImage: "timer")
                    .font(.subheadline)
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - SafetyFeatureRow
struct SafetyFeatureRow: View {
    let icon: String
    let title: String
    let detail: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
    }
}

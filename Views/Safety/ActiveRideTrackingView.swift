import SwiftUI
import MapKit

struct ActiveRideTrackingView: View {
    let route: Route
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var safetyManager = SafetyManager.shared
    @StateObject private var emergencyManager = EmergencyManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var showShareSheet = false
    @State private var showCompletionSheet = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showExitConfirmation = false
    
    // ✅ DÜZELTME: iOS 17+ için camera position
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
        ZStack {
            // ✅ DÜZELTME: Yeni Map API
            mapView
            
            VStack {
                // Top Navigation Bar
                topNavigationBar
                
                // Top Info Card
                topInfoCard
                
                Spacer()
                
                // Bottom Controls
                bottomControls
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startTracking()
            startTimer()
            setupCamera()
        }
        .onDisappear {
            stopTracking()
            stopTimer()
        }
        .sheet(isPresented: $showCompletionSheet) {
            RideCompletionSheet(route: route) {
                dismiss()
            }
        }
        .alert("Yolculuğu Bitir", isPresented: $showExitConfirmation) {
            Button("İptal", role: .cancel) { }
            Button("Evet, Bitir", role: .destructive) {
                safetyManager.completeSafetyCheck(safely: true)
                dismiss()
            }
        } message: {
            Text("Yolculuğu bitirmek istediğinize emin misiniz?")
        }
    }
    
    // ✅ DÜZELTME: Yeni Map API ile
    private var mapView: some View {
        ZStack {
            Map(position: $cameraPosition) {
                // ✅ Başlangıç noktası
                Marker(route.startLocation, coordinate: CLLocationCoordinate2D(
                    latitude: route.startLatitude,
                    longitude: route.startLongitude
                ))
                .tint(.green)
                
                // ✅ Bitiş noktası
                Marker(route.endLocation, coordinate: CLLocationCoordinate2D(
                    latitude: route.endLatitude,
                    longitude: route.endLongitude
                ))
                .tint(.red)
                
                // ✅ Mevcut konum - Custom annotation
                if let location = locationManager.currentLocation {
                    Annotation("Buradasınız", coordinate: location.coordinate) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 40, height: 40)
                            
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        }
                    }
                }
                
                // ✅ Rota çizgisi
                MapPolyline(coordinates: routeCoordinates)
                    .stroke(Color.blue, lineWidth: 3)
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .edgesIgnoringSafeArea(.all)
            
            // Gradient Overlay
            LinearGradient(
                colors: [Color.black.opacity(0.3), Color.clear, Color.black.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            .allowsHitTesting(false)
            
            // Konum Bilgileri Overlay
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        // GPS Status
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("GPS Aktif")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(15)
                        
                        // Konum Bilgisi
                        if let location = locationManager.currentLocation {
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "location.fill")
                                        .font(.caption2)
                                    Text("Konum")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                }
                                
                                Text(String(format: "%.6f, %.6f",
                                    location.coordinate.latitude,
                                    location.coordinate.longitude))
                                    .font(.system(size: 10, design: .monospaced))
                                
                                Text("Doğruluk: ±\(Int(location.horizontalAccuracy))m")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.trailing, 12)
                    .padding(.bottom, 200)
                }
            }
        }
    }
    
    // ✅ YENİ: Rota koordinatları
    private var routeCoordinates: [CLLocationCoordinate2D] {
        var coords: [CLLocationCoordinate2D] = []
        
        // Başlangıç
        coords.append(CLLocationCoordinate2D(
            latitude: route.startLatitude,
            longitude: route.startLongitude
        ))
        
        // Mevcut konum varsa ekle
        if let location = locationManager.currentLocation {
            coords.append(location.coordinate)
        }
        
        // Bitiş
        coords.append(CLLocationCoordinate2D(
            latitude: route.endLatitude,
            longitude: route.endLongitude
        ))
        
        return coords
    }
    
    private var topNavigationBar: some View {
        HStack {
            // Ana Sayfa Butonu
            Button(action: {
                showExitConfirmation = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 18))
                    Text("Ana Sayfa")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.blue)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            
            Spacer()
            
            // SOS Butonu
            Button(action: {
                EmergencyManager.shared.activateEmergency(reason: .general)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "sos")
                        .font(.system(size: 16, weight: .bold))
                    Text("SOS")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color.red, Color.red.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
                .shadow(color: .red.opacity(0.4), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal)
        .padding(.top, 50)
    }
    
    private var topInfoCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.green)
                        Text(route.startLocation)
                            .font(.headline)
                    }
                    
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.red)
                        Text(route.endLocation)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(route.estimatedDuration) dk")
                        .font(.headline)
                        .foregroundColor(.blue)
                    Text("Tahmini")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if locationManager.isDeviatingFromRoute {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Rota sapması tespit edildi!")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Stats
            HStack(spacing: 20) {
                StatView(
                    icon: "location.fill",
                    value: String(format: "%.1f km", locationManager.totalDistance / 1000),
                    label: "Mesafe"
                )
                StatView(
                    icon: "clock.fill",
                    value: timeElapsed,
                    label: "Süre"
                )
                StatView(
                    icon: "speedometer",
                    value: currentSpeed,
                    label: "Hız"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.95))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding()
    }
    
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Share Location
            Button(action: { shareLocation() }) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Konumu Paylaş")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            // Complete Ride
            Button(action: completeRide) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Güvenli Geldim")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.green, Color.green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.95))
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -4)
    }
    
    private var timeElapsed: String {
        let minutes = Int(elapsedTime / 60)
        let seconds = Int(elapsedTime.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var currentSpeed: String {
        if let speed = locationManager.currentLocation?.speed, speed > 0 {
            return String(format: "%.0f km/h", speed * 3.6)
        }
        return "0 km/h"
    }
    
    // ✅ DÜZELTME: Camera setup
    private func setupCamera() {
        let centerLat = (route.startLatitude + route.endLatitude) / 2
        let centerLon = (route.startLongitude + route.endLongitude) / 2
        
        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
        
        let latDelta = abs(route.startLatitude - route.endLatitude) * 1.5
        let lonDelta = abs(route.startLongitude - route.endLongitude) * 1.5
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(latDelta, 0.05),
            longitudeDelta: max(lonDelta, 0.05)
        )
        
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime += 1
            
            // Her 5 saniyede bir kamerayı güncelle
            if Int(elapsedTime) % 5 == 0 {
                updateCamera()
            }
        }
    }
    
    private func updateCamera() {
        if let location = locationManager.currentLocation {
            withAnimation {
                cameraPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func startTracking() {
        safetyManager.startSafetyCheck(for: route, estimatedDuration: route.estimatedDuration)
        
        if safetyManager.trustedContactsEnabled {
            safetyManager.shareTripWithContacts(route: route)
        }
    }
    
    private func stopTracking() {
        locationManager.stopTracking()
    }
    
    private func completeRide() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        safetyManager.completeSafetyCheck(safely: true)
        showCompletionSheet = true
    }
    
    private func shareLocation() {
        let message = locationManager.getLocationShareMessage()
        
        if let url = URL(string: "whatsapp://send?text=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                if let smsURL = URL(string: "sms:&body=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                    UIApplication.shared.open(smsURL)
                }
            }
        }
    }
}

struct StatView: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RideCompletionSheet: View {
    let route: Route
    var onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var showReviewView = false
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
            }
            .padding(.top, 40)
            
            VStack(spacing: 8) {
                Text("Güvenli Geldiniz! 🎉")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Yolculuğunuz başarıyla tamamlandı")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(.green)
                            Text(route.startLocation)
                                .font(.subheadline)
                        }
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(.red)
                            Text(route.endLocation)
                                .font(.subheadline)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text("\(route.estimatedDuration) dk")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .font(.caption)
                            Text("Tamamlandı")
                                .font(.caption)
                        }
                        .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: {
                    showReviewView = true
                }) {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Sürücüyü Değerlendir")
                    }
                    .fontWeight(.semibold)
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
                }
                
                Button(action: {
                    dismiss()
                    onDismiss()
                }) {
                    Text("Kapat")
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showReviewView) {
            CreateReviewView(
                reviewedUserId: route.driverId,
                reviewedUserName: route.driverName,
                routeId: route.id
            )
            .environmentObject(ReviewViewModel())
            .environmentObject(AuthViewModel())
        }
    }
}

// Custom corner radius extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

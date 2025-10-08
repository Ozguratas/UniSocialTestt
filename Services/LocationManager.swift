import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isTracking = false
    @Published var lastKnownLocation: CLLocation?
    @Published var locationError: String?
    
    // Route tracking için
    @Published var routePath: [CLLocation] = []
    @Published var totalDistance: Double = 0.0
    @Published var isDeviatingFromRoute = false
    
    private var trackingStartTime: Date?
    private var expectedRoute: [CLLocationCoordinate2D] = []
    
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10 metre değişimde güncelle
        
        // ✅ DÜZELTME: Background location'ı sadece izin varsa aktifleştir
        #if DEBUG
        // Debug mode'da background location'ı devre dışı bırak
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.showsBackgroundLocationIndicator = false
        #else
        // Release mode'da sadece "Always" izni varsa aktifleştir
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.showsBackgroundLocationIndicator = true
        }
        #endif
        
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    // MARK: - Public Methods
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
        // Always authorization için sadece gerektiğinde iste
        // locationManager.requestAlwaysAuthorization()
    }
    
    func startTracking() {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            locationError = "Konum izni gerekli"
            Logger.warning("Location permission not granted")
            return
        }
        
        // ✅ Background updates'i sadece Always izni varsa aktifleştir
        if authorizationStatus == .authorizedAlways {
            #if !DEBUG
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.showsBackgroundLocationIndicator = true
            #endif
        }
        
        locationManager.startUpdatingLocation()
        
        // ✅ Significant location changes sadece background tracking gerekiyorsa
        if authorizationStatus == .authorizedAlways {
            locationManager.startMonitoringSignificantLocationChanges()
        }
        
        isTracking = true
        trackingStartTime = Date()
        routePath.removeAll()
        totalDistance = 0.0
        
        Logger.info("Location tracking started")
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        
        if authorizationStatus == .authorizedAlways {
            locationManager.stopMonitoringSignificantLocationChanges()
        }
        
        // Background updates'i durdur
        #if !DEBUG
        locationManager.allowsBackgroundLocationUpdates = false
        #endif
        
        isTracking = false
        trackingStartTime = nil
        
        Logger.info("Location tracking stopped")
    }
    
    func startRouteTracking(expectedRoute: [CLLocationCoordinate2D]) {
        self.expectedRoute = expectedRoute
        startTracking()
    }
    
    func getDistanceBetween(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    func isLocationNearRoute(threshold: Double = 500) -> Bool {
        guard let current = currentLocation else { return false }
        
        for coordinate in expectedRoute {
            let distance = getDistanceBetween(
                from: current.coordinate,
                to: coordinate
            )
            if distance <= threshold {
                return true
            }
        }
        return false
    }
    
    // MARK: - Emergency Location Share
    
    func getLocationShareMessage() -> String {
        guard let location = currentLocation else {
            return "Konumum alınamadı"
        }
        
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let timestamp = Date().formatted(date: .long, time: .shortened)
        
        return """
        🚨 Acil Durum - UniSocial Yolculuk
        
        Konumum: https://maps.google.com/?q=\(lat),\(lon)
        
        Zaman: \(timestamp)
        
        Lütfen beni takip edin!
        """
    }
    
    func getLocationShareURL() -> URL? {
        guard let location = currentLocation else { return nil }
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        return URL(string: "https://maps.google.com/?q=\(lat),\(lon)")
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location
            self.lastKnownLocation = location
            
            if self.isTracking {
                self.routePath.append(location)
                
                // Calculate total distance
                if self.routePath.count > 1 {
                    let previousLocation = self.routePath[self.routePath.count - 2]
                    self.totalDistance += location.distance(from: previousLocation)
                }
                
                // Check route deviation
                if !self.expectedRoute.isEmpty {
                    self.isDeviatingFromRoute = !self.isLocationNearRoute()
                    
                    if self.isDeviatingFromRoute {
                        Logger.error("Route deviation detected!")
                        // Trigger safety alert
                        NotificationCenter.default.post(
                            name: NSNotification.Name("RouteDeviationDetected"),
                            object: nil
                        )
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error.localizedDescription
            Logger.error("Location error: \(error.localizedDescription)")
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                Logger.info("Location permission granted: \(manager.authorizationStatus)")
                
                // Always izni varsa background updates'i aktifleştir
                #if !DEBUG
                if manager.authorizationStatus == .authorizedAlways {
                    self.locationManager.allowsBackgroundLocationUpdates = true
                    self.locationManager.showsBackgroundLocationIndicator = true
                }
                #endif
                
            case .denied, .restricted:
                self.locationError = "Konum izni reddedildi"
                Logger.error("Location permission denied")
                
            case .notDetermined:
                Logger.info("Location permission not determined")
                
            @unknown default:
                break
            }
        }
    }
}

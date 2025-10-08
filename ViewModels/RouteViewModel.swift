//
//  RouteViewModel.swift
//  UniSocial
//
//  Created by Deniz on 6.10.2025.
//

import Foundation
import Foundation
import SwiftUI
import Combine

class RouteViewModel: ObservableObject {
    @Published var routes: [Route] = []
    @Published var filterStartLocation = ""
    @Published var filterEndLocation = ""
    @Published var filterDate: Date?
    @Published var isLoading = false
    
    init() {
        loadRoutesFromCache()
        loadSampleData()
    }
    
    private func loadRoutesFromCache() {
        let cached = LocalStorageManager.shared.loadCachedRoutes()
        if !cached.isEmpty {
            self.routes = cached
        }
    }
    
    func loadSampleData() {
        routes = [
            Route(
                id: "1",
                driverId: "user1",
                driverName: "Ahmet Yılmaz",
                driverRating: 4.8,
                driverGender: "Erkek",
                startLocation: "Maslak",
                endLocation: "Kadıköy",
                startLatitude: 41.1057,
                startLongitude: 29.0250,
                endLatitude: 40.9902,
                endLongitude: 29.0244,
                departureTime: Date().addingTimeInterval(AppConstants.TimeIntervals.oneHour),
                availableSeats: 3,
                passengers: [],
                vehicleInfo: "Renault Clio",
                isActive: true,
                isRecurring: false,
                recurringDays: [],
                preferences: RoutePreferences(
                    smokingAllowed: false,
                    petsAllowed: false,
                    musicPreference: "Pop",
                    chatLevel: "Orta",
                    genderPreference: "Hepsi",
                    luggageSpace: "Orta"
                ),
                meetingPoint: "Maslak Metro",
                estimatedDuration: 45,
                distance: 25.5,
                note: "Rahat yolculuk"
            )
        ]
        LocalStorageManager.shared.cacheRoutes(routes)
    }
    
    var filteredRoutes: [Route] {
        var filtered = routes
        
        if !filterStartLocation.isEmpty {
            filtered = filtered.filter { $0.startLocation.localizedCaseInsensitiveContains(filterStartLocation) }
        }
        
        if !filterEndLocation.isEmpty {
            filtered = filtered.filter { $0.endLocation.localizedCaseInsensitiveContains(filterEndLocation) }
        }
        
        if let date = filterDate {
            filtered = filtered.filter { Calendar.current.isDate($0.departureTime, inSameDayAs: date) }
        }
        
        return filtered
    }
    
    func createRoute(_ route: Route) {
        routes.insert(route, at: 0)
        LocalStorageManager.shared.cacheRoutes(routes)
    }
    
    func resetFilters() {
        filterStartLocation = ""
        filterEndLocation = ""
        filterDate = nil
    }
}

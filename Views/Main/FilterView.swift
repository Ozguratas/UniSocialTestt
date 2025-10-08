import SwiftUI

struct FilterView: View {
    @EnvironmentObject var routeViewModel: RouteViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Konum Filtreleri")) {
                    TextField("Başlangıç Noktası", text: $routeViewModel.filterStartLocation)
                        .textContentType(.location)
                    
                    TextField("Varış Noktası", text: $routeViewModel.filterEndLocation)
                        .textContentType(.location)
                }
                
                Section(header: Text("Tarih Filtresi")) {
                    Toggle("Tarih Filtrele", isOn: Binding(
                        get: { routeViewModel.filterDate != nil },
                        set: { newValue in
                            if newValue {
                                routeViewModel.filterDate = Date()
                            } else {
                                routeViewModel.filterDate = nil
                            }
                        }
                    ))
                    
                    if routeViewModel.filterDate != nil {
                        DatePicker(
                            "Tarih Seç",
                            selection: Binding(
                                get: { routeViewModel.filterDate ?? Date() },
                                set: { routeViewModel.filterDate = $0 }
                            ),
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .environment(\.locale, Locale(identifier: "tr_TR"))
                    }
                }
                
                Section {
                    Button(action: applyFilters) {
                        HStack {
                            Spacer()
                            Text("Filtreleri Uygula")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    
                    Button(action: resetFilters) {
                        HStack {
                            Spacer()
                            Text("Filtreleri Temizle")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
                
                // Aktif Filtreler Özeti
                if hasActiveFilters {
                    Section(header: Text("Aktif Filtreler")) {
                        if !routeViewModel.filterStartLocation.isEmpty {
                            HStack {
                                Image(systemName: "location.circle.fill")
                                    .foregroundColor(.green)
                                Text("Başlangıç: \(routeViewModel.filterStartLocation)")
                                    .font(.subheadline)
                            }
                        }
                        
                        if !routeViewModel.filterEndLocation.isEmpty {
                            HStack {
                                Image(systemName: "location.circle.fill")
                                    .foregroundColor(.red)
                                Text("Varış: \(routeViewModel.filterEndLocation)")
                                    .font(.subheadline)
                            }
                        }
                        
                        if let date = routeViewModel.filterDate {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                Text("Tarih: \(date.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.subheadline)
                            }
                            .environment(\.locale, Locale(identifier: "tr_TR"))
                        }
                    }
                }
            }
            .navigationTitle("Filtreler")
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
    
    private var hasActiveFilters: Bool {
        !routeViewModel.filterStartLocation.isEmpty ||
        !routeViewModel.filterEndLocation.isEmpty ||
        routeViewModel.filterDate != nil
    }
    
    private func applyFilters() {
        // Filtreler zaten RouteViewModel'de uygulanıyor (filteredRoutes computed property)
        dismiss()
    }
    
    private func resetFilters() {
        routeViewModel.resetFilters()
    }
}

// MARK: - Preview
#Preview {
    FilterView()
        .environmentObject(RouteViewModel())
}

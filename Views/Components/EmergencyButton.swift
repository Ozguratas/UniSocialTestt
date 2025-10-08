import SwiftUI

struct EmergencyButton: View {
    @StateObject private var emergencyManager = EmergencyManager.shared
    @State private var showEmergencySheet = false
    @State private var pressTimer: Timer?
    @State private var pressProgress: Double = 0.0
    @State private var isPressing = false
    
    var body: some View {
        VStack {
            if emergencyManager.isEmergencyActive {
                activeEmergencyButton
            } else {
                sosButton
            }
        }
        .sheet(isPresented: $showEmergencySheet) {
            EmergencyReasonSheet()
        }
    }
    
    private var sosButton: some View {
        Button(action: {}) {
            ZStack {
                // Pulse animasyonu
                Circle()
                    .fill(Color.red.opacity(0.3))
                    .frame(width: isPressing ? 100 : 80, height: isPressing ? 100 : 80)
                    .scaleEffect(isPressing ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isPressing)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .red.opacity(0.4), radius: 10, x: 0, y: 4)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: pressProgress)
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 76, height: 76)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: pressProgress)
                
                VStack(spacing: 4) {
                    Image(systemName: "sos")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(isPressing ? "Basılı Tut" : "SOS")
                        .font(isPressing ? .caption2 : .caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 2.0)
                .onEnded { _ in
                    triggerEmergency()
                }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressing {
                        isPressing = true
                        startPressTimer()
                    }
                }
                .onEnded { _ in
                    isPressing = false
                    cancelPressTimer()
                }
        )
    }
    
    private var activeEmergencyButton: some View {
        VStack(spacing: 12) {
            ZStack {
                // Daha belirgin animasyon
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .scaleEffect(1.5)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: emergencyManager.isEmergencyActive)
                
                Circle()
                    .fill(Color.red)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .scaleEffect(1.1)
                            .opacity(0.8)
                    )
                    .shadow(color: .red.opacity(0.6), radius: 20, x: 0, y: 0)
                
                VStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                    
                    Text("AKTİF")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            Button(action: deactivateEmergency) {
                Text("İptal Et")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(25)
                    .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    private func startPressTimer() {
        pressProgress = 0
        pressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if pressProgress < 1.0 {
                pressProgress += 0.025
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func cancelPressTimer() {
        pressTimer?.invalidate()
        pressTimer = nil
        withAnimation(.easeOut(duration: 0.3)) {
            pressProgress = 0
        }
    }
    
    private func triggerEmergency() {
        // ✅ DÜZELTME: UIKit haptic feedback kullan
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        // ✅ DÜZELTME: Impact feedback ekle (vibration benzeri)
        let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
        impactGenerator.impactOccurred()
        
        // Show reason selection
        showEmergencySheet = true
        
        cancelPressTimer()
        isPressing = false
    }
    
    private func deactivateEmergency() {
        let alert = UIAlertController(
            title: "Acil Durumu İptal Et",
            message: "Güvende misiniz? Acil durum iptal edilecek.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        alert.addAction(UIAlertAction(title: "Evet, Güvendeyim", style: .default) { _ in
            emergencyManager.deactivateEmergency()
            
            // ✅ Success haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
}

// MARK: - Emergency Reason Sheet
struct EmergencyReasonSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var emergencyManager = EmergencyManager.shared
    
    let reasons: [EmergencyReason] = [
        .general,
        .unsafeDriver,
        .harassment,
        .accident,
        .routeDeviation,
        .uncomfortable
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                }
                .padding(.top, 30)
                
                VStack(spacing: 8) {
                    Text("Acil Durum Sebebi")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Ne tür bir sorun yaşıyorsunuz?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(reasons, id: \.self) { reason in
                            EmergencyReasonButton(reason: reason) {
                                activateEmergency(reason: reason)
                            }
                        }
                    }
                    .padding()
                }
                
                Button(action: { dismiss() }) {
                    Text("İptal")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarHidden(true)
        }
    }
    
    private func activateEmergency(reason: EmergencyReason) {
        emergencyManager.activateEmergency(reason: reason)
        dismiss()
    }
}

struct EmergencyReasonButton: View {
    let reason: EmergencyReason
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: iconForReason)
                    .font(.title3)
                    .foregroundColor(.red)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(reason.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(descriptionForReason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var iconForReason: String {
        switch reason {
        case .general: return "exclamationmark.circle.fill"
        case .unsafeDriver: return "car.fill"
        case .harassment: return "hand.raised.fill"
        case .accident: return "bandage.fill"
        case .routeDeviation: return "location.slash.fill"
        case .uncomfortable: return "person.fill.questionmark"
        }
    }
    
    private var descriptionForReason: String {
        switch reason {
        case .general: return "Acil yardım gerekiyor"
        case .unsafeDriver: return "Sürücü güvensiz sürüş yapıyor"
        case .harassment: return "Tacize uğruyorum"
        case .accident: return "Kaza geçirdik"
        case .routeDeviation: return "Planlanmayan rotadayız"
        case .uncomfortable: return "Kendimi güvende hissetmiyorum"
        }
    }
}

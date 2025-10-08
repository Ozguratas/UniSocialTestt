import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var backgroundColor: Color = .blue
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(title).font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: AppConstants.UI.buttonHeight)
            .background(isEnabled && !isLoading ? backgroundColor : Color.gray)
            .cornerRadius(AppConstants.UI.cornerRadius)
        }
        .disabled(!isEnabled || isLoading)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    var foregroundColor: Color = .blue
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(isEnabled ? foregroundColor : .gray)
                .frame(maxWidth: .infinity)
                .frame(height: AppConstants.UI.buttonHeight)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                        .stroke(isEnabled ? foregroundColor : Color.gray, lineWidth: 2)
                )
        }
        .disabled(!isEnabled)
    }
}

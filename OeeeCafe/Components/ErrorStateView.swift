import SwiftUI

/// Reusable error state view with icon, message, and retry button
struct ErrorStateView: View {
    let error: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
                .accessibilityHidden(true)

            Text("common.error".localized(error))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("common.retry".localized) {
                onRetry()
            }
            .buttonStyle(.bordered)
            .accessibilityHint("Retry loading the content")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .padding(.top, 100)
    }
}

#Preview {
    ErrorStateView(error: "Network connection failed") {
        print("Retry tapped")
    }
}

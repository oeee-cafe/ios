import SwiftUI

/// Reusable loading state view with progress indicator and message
struct LoadingStateView: View {
    let message: String

    init(message: String = "common.loading".localized) {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text(message)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

#Preview {
    LoadingStateView()
}

#Preview("Custom Message") {
    LoadingStateView(message: "Loading posts...")
}

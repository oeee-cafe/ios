import SwiftUI

/// Reusable empty state view with custom icon and message
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String?

    init(icon: String, title: String, message: String? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray)
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)

            if let message = message {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .padding(.top, 100)
    }
}

#Preview("No Results") {
    EmptyStateView(
        icon: "magnifyingglass",
        title: "No results found",
        message: "Try searching for a different keyword"
    )
}

#Preview("No Notifications") {
    EmptyStateView(
        icon: "bell.slash",
        title: "No notifications",
        message: "When you get notifications, they'll show up here"
    )
}

#Preview("No Posts") {
    EmptyStateView(
        icon: "photo.on.rectangle.angled",
        title: "No posts yet"
    )
}

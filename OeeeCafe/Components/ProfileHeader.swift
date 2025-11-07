import SwiftUI

struct ProfileHeader: View {
    let displayName: String
    let loginName: String

    var body: some View {
        VStack(spacing: 8) {
            Text(displayName)
                .font(.title)
                .fontWeight(.bold)

            Text("@\(loginName)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

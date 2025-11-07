import SwiftUI

struct SearchUserResultsList: View {
    let users: [SearchUser]

    var body: some View {
        if !users.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("search.users_count".localized(users.count))
                    .font(.headline)
                    .padding(.horizontal)

                ForEach(users) { user in
                    NavigationLink(destination: ProfileView(loginName: user.loginName)) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)

                                Text("@\(user.loginName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
            }
            .padding(.top)
        }
    }
}

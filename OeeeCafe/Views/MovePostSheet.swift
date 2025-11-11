import SwiftUI

struct MovePostSheet: View {
    let postId: String
    @Environment(\.dismiss) private var dismiss
    @State private var communities: [MovableCommunity] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isMoving = false
    @State private var searchText = ""

    // Computed properties for filtering and grouping
    private var filteredCommunities: [MovableCommunity] {
        if searchText.isEmpty {
            return communities
        }
        return communities.filter { community in
            community.name.localizedCaseInsensitiveContains(searchText) ||
            (community.slug?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var personalPostOption: MovableCommunity? {
        filteredCommunities.first { $0.isPersonalPost }
    }

    private var unlistedCommunities: [MovableCommunity] {
        filteredCommunities
            .filter { $0.visibility == "unlisted" }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    private var publicParticipatedCommunities: [MovableCommunity] {
        filteredCommunities
            .filter { $0.visibility == "public" && $0.hasParticipated == true }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    private var publicOtherCommunities: [MovableCommunity] {
        filteredCommunities
            .filter { $0.visibility == "public" && $0.hasParticipated == false }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("post.move_loading".localized)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        Text("post.move_error".localized)
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if communities.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("post.move_cannot_move_title".localized)
                            .font(.headline)
                        Text("post.move_cannot_move_message".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    List {
                        if let personalPost = personalPostOption {
                            CommunityRow(community: personalPost)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    movePost(to: personalPost)
                                }
                        }

                        if !unlistedCommunities.isEmpty {
                            Section(header: Text("move.section.unlisted".localized)) {
                                ForEach(unlistedCommunities, id: \.listId) { community in
                                    CommunityRow(community: community)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            movePost(to: community)
                                        }
                                }
                            }
                        }

                        if !publicParticipatedCommunities.isEmpty {
                            Section(header: Text("move.section.public_participated".localized)) {
                                ForEach(publicParticipatedCommunities, id: \.listId) { community in
                                    CommunityRow(community: community)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            movePost(to: community)
                                        }
                                }
                            }
                        }

                        if !publicOtherCommunities.isEmpty {
                            Section(header: Text("move.section.public_other".localized)) {
                                ForEach(publicOtherCommunities, id: \.listId) { community in
                                    CommunityRow(community: community)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            movePost(to: community)
                                        }
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "move.search.placeholder".localized)
                }
            }
            .navigationTitle("post.move_to_community".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                    .disabled(isMoving)
                }
            }
        }
        .task {
            await loadCommunities()
        }
        .overlay {
            if isMoving {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("post.move_moving".localized)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        }
    }

    private func loadCommunities() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await PostService.shared.fetchMovableCommunities(postId: postId)
            communities = response.communities
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func movePost(to community: MovableCommunity) {
        Task {
            isMoving = true

            do {
                try await PostService.shared.movePostToCommunity(
                    postId: postId,
                    communityId: community.id
                )
                dismiss()
            } catch {
                errorMessage = "Failed to move post: \(error.localizedDescription)"
            }

            isMoving = false
        }
    }
}

struct CommunityRow: View {
    let community: MovableCommunity

    var body: some View {
        HStack(spacing: 12) {
            // Community icon
            if community.isPersonalPost {
                Image(systemName: "person.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(communityColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(community.name.prefix(1)).uppercased())
                            .font(.headline)
                            .foregroundColor(.white)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(community.isPersonalPost ? "post.move_personal_post".localized : community.name)
                    .font(.headline)

                if let ownerDisplay = community.ownerDisplayName,
                   let ownerLogin = community.ownerLoginName {
                    Text(String(format: "common.by".localized, "\(ownerDisplay) (@\(ownerLogin))"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let visibility = community.visibility {
                    HStack(spacing: 4) {
                        Image(systemName: visibilityIcon(for: visibility))
                            .font(.caption2)
                        Text(visibility.capitalized)
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var communityColor: Color {
        if let bgColor = community.backgroundColor, !bgColor.isEmpty {
            return Color(hex: bgColor) ?? .blue
        }
        return .blue
    }

    private func visibilityIcon(for visibility: String) -> String {
        switch visibility {
        case "public":
            return "globe"
        case "unlisted":
            return "link"
        case "private":
            return "lock.fill"
        default:
            return "questionmark"
        }
    }
}

// Color extension to parse hex colors
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

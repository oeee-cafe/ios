import SwiftUI
import Combine

struct CommunityInvitationsView: View {
    @StateObject private var viewModel = CommunityInvitationsViewModel()
    @State private var navigateToCommunitySlug: String?

    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else if viewModel.invitations.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "envelope.open")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("community_invitations.no_invitations".localized)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("community_invitations.no_invitations_message".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.invitations) { invitation in
                    InvitationCard(
                        invitation: invitation,
                        onAccept: {
                            Task {
                                await viewModel.acceptInvitation(invitation.id)
                                // Navigate to the accepted community after successful acceptance
                                if !viewModel.showError {
                                    navigateToCommunitySlug = invitation.community.slug
                                }
                            }
                        },
                        onReject: {
                            Task {
                                await viewModel.rejectInvitation(invitation.id)
                            }
                        }
                    )
                }
            }
        }
        .navigationTitle("community_invitations.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadInvitations()
        }
        .task {
            await viewModel.loadInvitations()
        }
        .alert("common.error".localized, isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("common.ok".localized) {}
        } message: { message in
            Text(message)
        }
        .navigationDestination(item: $navigateToCommunitySlug) { slug in
            CommunityDetailView(slug: slug)
        }
    }
}

struct InvitationCard: View {
    let invitation: UserInvitation
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Community Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(invitation.community.name)
                        .font(.headline)
                    Spacer()
                    VisibilityBadge(visibility: invitation.community.visibility)
                }
                Text("@\(invitation.community.slug)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if !invitation.community.description.isEmpty {
                    Text(invitation.community.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Divider()

            // Inviter Info
            HStack {
                Image(systemName: "person.circle")
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("community_invitations.invited_by".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(invitation.inviter.displayName)
                        .font(.subheadline)
                    Text("@\(invitation.inviter.username)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Action Buttons
            HStack(spacing: 12) {
                Button(action: onReject) {
                    Text("community_invitations.decline".localized)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .tint(.gray)

                Button(action: onAccept) {
                    Text("community_invitations.accept".localized)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 8)
    }
}

struct VisibilityBadge: View {
    let visibility: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption)
            Text(localizedVisibility)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .foregroundColor(.white)
        .cornerRadius(8)
    }

    private var localizedVisibility: String {
        switch visibility {
        case "public": return "create_community.visibility_public".localized
        case "unlisted": return "create_community.visibility_unlisted".localized
        case "private": return "create_community.visibility_private".localized
        default: return visibility.capitalized
        }
    }

    private var iconName: String {
        switch visibility {
        case "public": return "globe"
        case "unlisted": return "link"
        case "private": return "lock"
        default: return "questionmark"
        }
    }

    private var backgroundColor: Color {
        switch visibility {
        case "public": return .green
        case "unlisted": return .orange
        case "private": return .purple
        default: return .gray
        }
    }
}

@MainActor
class CommunityInvitationsViewModel: ObservableObject {
    @Published var invitations: [UserInvitation] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?

    private let communityService = CommunityService.shared

    func loadInvitations() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await communityService.getUserInvitations()
            invitations = response.invitations
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func acceptInvitation(_ id: String) async {
        do {
            try await communityService.acceptInvitation(id: id)
            await loadInvitations()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func rejectInvitation(_ id: String) async {
        do {
            try await communityService.rejectInvitation(id: id)
            await loadInvitations()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

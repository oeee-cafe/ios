import SwiftUI
import Combine

struct CommunityMembersView: View {
    @StateObject private var viewModel: CommunityMembersViewModel
    @ObservedObject private var authService = AuthService.shared
    @State private var showInviteSheet = false
    @State private var showingRemoveAlert = false
    @State private var memberToRemove: CommunityMember?
    @State private var showingLeaveAlert = false
    @Environment(\.dismiss) private var dismiss

    let onLeave: () -> Void

    init(slug: String, isOwner: Bool, isOwnerOrModerator: Bool, onLeave: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: CommunityMembersViewModel(slug: slug, isOwner: isOwner, isOwnerOrModerator: isOwnerOrModerator))
        self.onLeave = onLeave
    }

    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else {
                // Members Section
                Section {
                    ForEach(viewModel.members) { member in
                        MemberRow(
                            member: member,
                            canManage: viewModel.isOwnerOrModerator && member.role != "owner",
                            isCurrentUser: member.userId == authService.currentUser?.id,
                            onRemove: {
                                memberToRemove = member
                                showingRemoveAlert = true
                            },
                            onLeave: {
                                showingLeaveAlert = true
                            }
                        )
                    }
                }

                // Pending Invitations (only owners can manage invitations)
                if viewModel.isOwner && !viewModel.invitations.isEmpty {
                    Section("community_management.pending_invitations".localized) {
                        ForEach(viewModel.invitations) { invitation in
                            InvitationRow(
                                invitation: invitation,
                                onRetract: {
                                    Task {
                                        await viewModel.retractInvitation(invitation.id)
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("community_management.members".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.isOwner {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showInviteSheet = true }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
        }
        .refreshable {
            await viewModel.loadMembers()
        }
        .task {
            await viewModel.loadMembers()
        }
        .sheet(isPresented: $showInviteSheet) {
            InviteUserSheet(slug: viewModel.slug) {
                showInviteSheet = false
                Task {
                    await viewModel.loadMembers()
                }
            }
        }
        .alert("community_management.remove_member".localized, isPresented: $showingRemoveAlert, presenting: memberToRemove) { member in
            Button("common.cancel".localized, role: .cancel) {}
            Button("community_management.remove".localized, role: .destructive) {
                Task {
                    await viewModel.removeMember(member.userId)
                }
            }
        } message: { member in
            Text(String(format: "community_management.remove_confirm".localized, member.displayName))
        }
        .alert("community_management.leave_community".localized, isPresented: $showingLeaveAlert) {
            Button("common.cancel".localized, role: .cancel) {}
            Button("community_management.leave".localized, role: .destructive) {
                Task {
                    await viewModel.leaveCommunity()
                    if !viewModel.showError {
                        dismiss()
                        onLeave()
                    }
                }
            }
        } message: {
            Text("community_management.leave_confirm".localized)
        }
        .alert("common.error".localized, isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("common.ok".localized) {}
        } message: { message in
            Text(message)
        }
    }
}

struct MemberRow: View {
    let member: CommunityMember
    let canManage: Bool
    let isCurrentUser: Bool
    let onRemove: () -> Void
    let onLeave: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(member.displayName)
                    .font(.headline)
                Text("@\(member.username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(localizedRole(member.role))
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(roleColor(for: member.role))
                .foregroundColor(.white)
                .cornerRadius(8)

            if canManage {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            } else if isCurrentUser && member.role != "owner" {
                Button(action: onLeave) {
                    Text("community_management.leave".localized)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private func localizedRole(_ role: String) -> String {
        switch role {
        case "owner": return "community_management.role_owner".localized
        case "moderator": return "community_management.role_moderator".localized
        case "member": return "community_management.role_member".localized
        default: return role.capitalized
        }
    }

    private func roleColor(for role: String) -> Color {
        switch role {
        case "owner": return .purple
        case "moderator": return .blue
        default: return .gray
        }
    }
}

struct InvitationRow: View {
    let invitation: CommunityInvitation
    let onRetract: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(invitation.invitee.displayName)
                    .font(.headline)
                Text("@\(invitation.invitee.username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("community_management.invited".localized)
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: onRetract) {
                Text("community_management.retract".localized)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

@MainActor
class CommunityMembersViewModel: ObservableObject {
    @Published var members: [CommunityMember] = []
    @Published var invitations: [CommunityInvitation] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?

    let slug: String
    let isOwner: Bool
    let isOwnerOrModerator: Bool
    private let communityService = CommunityService.shared

    init(slug: String, isOwner: Bool, isOwnerOrModerator: Bool) {
        self.slug = slug
        self.isOwner = isOwner
        self.isOwnerOrModerator = isOwnerOrModerator
    }

    func loadMembers() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await communityService.getCommunityMembers(slug: slug)
            members = response.members

            // Load invitations for owners (they can see pending invitations)
            if isOwner {
                let invitationsResponse = try await communityService.getCommunityInvitations(slug: slug)
                invitations = invitationsResponse.invitations
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func removeMember(_ userId: String) async {
        do {
            try await communityService.removeMember(slug: slug, userId: userId)
            await loadMembers()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func retractInvitation(_ invitationId: String) async {
        do {
            try await communityService.retractInvitation(slug: slug, invitationId: invitationId)
            await loadMembers()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func leaveCommunity() async {
        do {
            try await communityService.leaveCommunity(slug: slug)
            // Navigation back will be handled by the view
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

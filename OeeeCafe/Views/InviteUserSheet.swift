import SwiftUI

struct InviteUserSheet: View {
    let slug: String
    let onInvited: () -> Void

    @State private var loginName = ""
    @State private var isInviting = false
    @State private var showError = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private let communityService = CommunityService.shared

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("community_management.username".localized, text: $loginName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("community_management.invite_prompt".localized)
                }
            }
            .navigationTitle("community_management.invite_user".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("community_management.invite".localized) {
                        Task {
                            await inviteUser()
                        }
                    }
                    .disabled(loginName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isInviting)
                }
            }
            .alert("common.error".localized, isPresented: $showError, presenting: errorMessage) { _ in
                Button("common.ok".localized) {}
            } message: { message in
                Text(message)
            }
        }
    }

    private func inviteUser() async {
        let trimmedName = loginName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        isInviting = true
        defer { isInviting = false }

        do {
            try await communityService.inviteUser(slug: slug, loginName: trimmedName)
            await MainActor.run {
                dismiss()
                onInvited()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

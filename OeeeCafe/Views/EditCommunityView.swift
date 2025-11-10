import SwiftUI
import Combine

struct EditCommunityView: View {
    @StateObject private var viewModel: EditCommunityViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var confirmationSlug = ""
    @State private var isDeleting = false

    let onCommunityDeleted: (() -> Void)?

    init(slug: String, communityInfo: CommunityInfo, onCommunityDeleted: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: EditCommunityViewModel(slug: slug, communityInfo: communityInfo))
        self.onCommunityDeleted = onCommunityDeleted
    }

    var body: some View {
        Form {
            Section {
                TextField("create_community.name".localized, text: $viewModel.name)
                Text("common.id_prefix".localized(viewModel.slug))
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("create_community.basic_info".localized)
            }

            Section {
                TextEditor(text: $viewModel.description)
                    .frame(minHeight: 100)
            } header: {
                Text("create_community.description".localized)
            }

            // Only show visibility section for non-private communities
            if !viewModel.isPrivate {
                Section {
                    Picker("edit_community.visibility".localized, selection: $viewModel.visibility) {
                        ForEach(viewModel.allowedVisibilities, id: \.self) { vis in
                            Text(localizedVisibility(vis)).tag(vis)
                        }
                    }
                    .pickerStyle(.segmented)

                    visibilityDescription
                } header: {
                    Text("create_community.privacy".localized)
                }
            }

            // Danger Zone
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("edit_community.delete_warning".localized)
                        .font(.subheadline)
                        .foregroundColor(.red)

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("edit_community.delete_community".localized, systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                }
            } header: {
                Text("edit_community.danger_zone".localized)
            }
        }
        .navigationTitle("edit_community.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("edit_community.save".localized) {
                    Task {
                        await viewModel.updateCommunity()
                        if viewModel.updateSucceeded {
                            dismiss()
                        }
                    }
                }
                .disabled(!viewModel.isValid || viewModel.isUpdating)
            }
        }
        .alert("common.error".localized, isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("common.ok".localized) {}
        } message: { message in
            Text(message)
        }
        .alert("edit_community.delete_community".localized, isPresented: $showDeleteConfirmation) {
            TextField("edit_community.type_slug_to_confirm".localized, text: $confirmationSlug)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Button("common.cancel".localized, role: .cancel) {
                confirmationSlug = ""
            }

            Button("edit_community.delete_button".localized, role: .destructive) {
                Task {
                    await deleteCommunity()
                }
            }
            .disabled(confirmationSlug != viewModel.slug || isDeleting)
        } message: {
            Text("edit_community.delete_confirmation_message".localized)
        }
    }

    private func deleteCommunity() async {
        guard confirmationSlug == viewModel.slug else { return }

        isDeleting = true
        defer { isDeleting = false }

        do {
            try await CommunityService.shared.deleteCommunity(slug: viewModel.slug)
            await MainActor.run {
                onCommunityDeleted?()
                dismiss()
            }
        } catch {
            viewModel.errorMessage = error.localizedDescription
            viewModel.showError = true
        }
    }

    @ViewBuilder
    private var visibilityDescription: some View {
        switch viewModel.visibility {
        case "public":
            Text("create_community.visibility_public_desc".localized)
                .font(.caption)
                .foregroundColor(.secondary)
        case "unlisted":
            Text("create_community.visibility_unlisted_desc".localized)
                .font(.caption)
                .foregroundColor(.secondary)
        default:
            EmptyView()
        }
    }

    private func localizedVisibility(_ visibility: String) -> String {
        switch visibility {
        case "public": return "create_community.visibility_public".localized
        case "unlisted": return "create_community.visibility_unlisted".localized
        default: return visibility.capitalized
        }
    }
}

@MainActor
class EditCommunityViewModel: ObservableObject {
    @Published var name: String
    @Published var description: String
    @Published var visibility: String
    @Published var isUpdating = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var updateSucceeded = false

    let slug: String
    let originalVisibility: String
    private let communityService = CommunityService.shared

    var isPrivate: Bool {
        originalVisibility == "private"
    }

    var allowedVisibilities: [String] {
        if originalVisibility == "private" {
            return ["private"]
        } else {
            return ["public", "unlisted"]
        }
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(slug: String, communityInfo: CommunityInfo) {
        self.slug = slug
        self.name = communityInfo.name
        self.description = communityInfo.description ?? ""
        self.visibility = communityInfo.visibility
        self.originalVisibility = communityInfo.visibility
    }

    func updateCommunity() async {
        guard isValid else { return }

        isUpdating = true
        defer { isUpdating = false }

        let request = UpdateCommunityRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            visibility: visibility
        )

        do {
            try await communityService.updateCommunity(slug: slug, request: request)
            updateSucceeded = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

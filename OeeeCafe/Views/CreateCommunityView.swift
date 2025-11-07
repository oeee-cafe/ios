import SwiftUI
import Combine

struct CreateCommunityView: View {
    @StateObject private var viewModel = CreateCommunityViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("create_community.name".localized, text: $viewModel.name)
                    TextField("create_community.slug".localized, text: $viewModel.slug)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text(String(format: "create_community.slug_hint".localized, viewModel.slug))
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

                Section {
                    Picker("common.visibility".localized, selection: $viewModel.visibility) {
                        Text("create_community.visibility_public".localized).tag("public")
                        Text("create_community.visibility_unlisted".localized).tag("unlisted")
                        Text("create_community.visibility_private".localized).tag("private")
                    }
                    .pickerStyle(.segmented)

                    visibilityDescription
                } header: {
                    Text("create_community.privacy".localized)
                }
            }
            .navigationTitle("create_community.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("create_community.create".localized) {
                        Task {
                            await viewModel.createCommunity()
                            if viewModel.createdSlug != nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isCreating)
                }
            }
            .alert("common.error".localized, isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
                Button("common.ok".localized) {}
            } message: { message in
                Text(message)
            }
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
        case "private":
            Text("create_community.visibility_private_desc".localized)
                .font(.caption)
                .foregroundColor(.secondary)
        default:
            EmptyView()
        }
    }
}

@MainActor
class CreateCommunityViewModel: ObservableObject {
    @Published var name = ""
    @Published var slug = ""
    @Published var description = ""
    @Published var visibility = "public"
    @Published var isCreating = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var createdSlug: String?

    private let communityService = CommunityService.shared

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !slug.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        slug.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
    }

    func createCommunity() async {
        guard isValid else { return }

        isCreating = true
        defer { isCreating = false }

        let request = CreateCommunityRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            slug: slug.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            visibility: visibility
        )

        do {
            let response = try await communityService.createCommunity(request: request)
            createdSlug = response.community.slug
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

import SwiftUI
import Kingfisher

struct DraftsView: View {
    @StateObject private var viewModel = DraftsViewModel()
    @EnvironmentObject var authService: AuthService
    @State private var showSettings = false
    @State private var shouldNavigateToPost = false
    @State private var navigateToPost: String?
    @State private var selectedDraft: DraftPost?

    private let columns = Constants.postGridColumns

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading && viewModel.drafts.isEmpty {
                    LoadingStateView(message: "common.loading".localized)
                        .padding(.top, 100)
                } else if let error = viewModel.error, viewModel.drafts.isEmpty {
                    ErrorStateView(error: error) {
                        Task {
                            await viewModel.loadDrafts()
                        }
                    }
                    .padding(.top, 100)
                } else if viewModel.drafts.isEmpty {
                    EmptyStateView(
                        icon: "doc.text",
                        title: "drafts.empty_title".localized,
                        message: "drafts.empty_message".localized
                    )
                    .padding(.top, 100)
                } else {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(viewModel.drafts) { draft in
                            Button {
                                selectedDraft = draft
                            } label: {
                                DraftGridItem(draft: draft)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                }
            }
            .navigationTitle("drafts.title".localized)
            .refreshable {
                await Task { @MainActor in
                    await viewModel.refresh()
                }.value
            }
            .toolbar {
                if authService.isAuthenticated, let user = authService.currentUser {
                    ToolbarItem(placement: .navigationBarLeading) {
                        HStack(spacing: 12) {
                            NavigationLink(destination: ProfileView(loginName: user.loginName)) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.title3)
                            }

                            Button(action: {
                                showSettings = true
                            }) {
                                Image(systemName: "gear")
                                    .font(.title3)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(item: $selectedDraft) { draft in
                DraftPostView(
                    postId: draft.id,
                    communityId: draft.communityId,
                    imageUrl: draft.imageUrl,
                    onPublished: {
                        selectedDraft = nil
                        navigateToPost = draft.id
                        shouldNavigateToPost = true
                        // Refresh drafts list
                        Task {
                            await viewModel.refresh()
                        }
                    },
                    onCancel: {
                        selectedDraft = nil
                    }
                )
            }
            .navigationDestination(isPresented: $shouldNavigateToPost) {
                if let postId = navigateToPost {
                    PostDetailView(postId: postId)
                }
            }
        }
        .task {
            await viewModel.loadDrafts()
        }
    }
}

struct DraftGridItem: View {
    let draft: DraftPost

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            KFImage(URL(string: draft.imageUrl))
                .placeholder {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .clipped()
                .cornerRadius(4)

            if let title = draft.title, !title.isEmpty {
                Text(title)
                    .font(.caption2)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("drafts.untitled".localized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    DraftsView()
}

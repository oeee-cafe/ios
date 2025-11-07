import SwiftUI
import Kingfisher

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject var authService: AuthService
    @State private var showSettings = false
    @State private var shouldNavigateToPost = false
    @State private var navigateToPost: String?
    @State private var showDraftPost = false
    @State private var draftPostData: (postId: String, communityId: String, imageUrl: String)?

    private let postColumns = Constants.postGridColumns

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Users Section
                    SearchUserResultsList(users: viewModel.users)

                    // Posts Section
                    SearchPostResultsGrid(posts: viewModel.posts)

                    // Empty State
                    if !viewModel.isLoading && viewModel.users.isEmpty && viewModel.posts.isEmpty && !viewModel.searchText.isEmpty {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "search.no_results".localized,
                            message: "search.try_different".localized
                        )
                        .padding(.top, 100)
                    }

                    // Initial State
                    if viewModel.searchText.isEmpty {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "search.prompt".localized,
                            message: nil
                        )
                        .padding(.top, 100)
                    }

                    // Loading State
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView("common.loading".localized)
                            Spacer()
                        }
                        .padding()
                    }

                    // Error State
                    if let error = viewModel.error {
                        Text("common.error".localized(error))
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                    }
                }
            }
            .navigationTitle("search.title".localized)
            .searchable(text: $viewModel.searchText, prompt: "search.prompt".localized)
            .textInputAutocapitalization(.never)
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
            .sheet(isPresented: $showDraftPost) {
                if let data = draftPostData {
                    DraftPostView(
                        postId: data.postId,
                        communityId: data.communityId,
                        imageUrl: data.imageUrl,
                        onPublished: {
                            showDraftPost = false
                            navigateToPost = data.postId
                            shouldNavigateToPost = true
                        },
                        onCancel: {
                            showDraftPost = false
                        }
                    )
                }
            }
            .navigationDestination(isPresented: $shouldNavigateToPost) {
                if let postId = navigateToPost {
                    PostDetailView(postId: postId)
                }
            }
        }
    }
}

#Preview {
    SearchView()
}

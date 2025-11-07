import SwiftUI
import Kingfisher

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject var authService: AuthService
    @State private var showSettings = false

    init(loginName: String) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(loginName: loginName))
    }

    // Check if this is the current user's profile
    private var isCurrentUser: Bool {
        guard let currentUser = authService.currentUser else { return false }
        return currentUser.loginName == viewModel.loginName
    }

    private let columns = Constants.postGridColumns

    var body: some View {
        ScrollView {
            contentView
        }
        .navigationTitle(viewModel.profileDetail?.user.displayName ?? viewModel.loginName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Show settings button when viewing own profile OR when not authenticated
            if isCurrentUser || !authService.isAuthenticated {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            } else if authService.isAuthenticated, let profile = viewModel.profileDetail {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.toggleFollow()
                        }
                    } label: {
                        Label(
                            profile.user.isFollowing ? "profile.unfollow".localized : "profile.follow".localized,
                            systemImage: profile.user.isFollowing ? "person.fill.checkmark" : "person.badge.plus"
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(authService)
        }
        .refreshable {
            await Task { @MainActor in
                await viewModel.refresh()
            }.value
        }
        .task {
            await viewModel.loadProfile()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.profileDetail == nil {
            LoadingStateView(message: "profile.loading".localized)
                .padding(.top, 100)
        } else if let error = viewModel.error, viewModel.profileDetail == nil {
            ErrorStateView(error: error) {
                Task {
                    await viewModel.loadProfile()
                }
            }
            .padding(.top, 100)
        } else if let detail = viewModel.profileDetail {
            VStack(spacing: 24) {
                // Banner
                if let banner = detail.banner {
                    ProfileBannerView(imageUrl: banner.imageUrl)
                }

                // Profile Header
                ProfileHeader(displayName: detail.user.displayName, loginName: detail.user.loginName)

                // Links Section
                ProfileLinksSection(links: detail.links)

                // Followings Section
                ProfileFollowingsSection(followings: detail.followings, totalFollowings: detail.totalFollowings, loginName: detail.user.loginName)
                    .environmentObject(authService)

                // Posts Section
                ProfilePostsSection(
                    posts: viewModel.posts,
                    isLoadingMore: viewModel.isLoadingMore,
                    hasMore: viewModel.hasMore,
                    onLoadMore: { await viewModel.loadMorePosts() }
                )
            }
            .padding(.bottom)
        }
    }
}

struct ProfilePostGridItem: View {
    let post: ProfilePost

    var body: some View {
        AsyncImageGrid(imageUrl: post.imageUrl)
    }
}

#Preview {
    NavigationView {
        ProfileView(loginName: "example")
    }
}

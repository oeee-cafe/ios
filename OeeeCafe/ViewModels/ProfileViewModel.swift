import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profileDetail: ProfileDetail?
    @Published var posts: [ProfilePost] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: String?
    @Published var hasMore = false

    private let postService = PostService.shared
    private var currentOffset = 0
    let loginName: String

    init(loginName: String) {
        self.loginName = loginName
    }

    func loadProfile() async {
        // Don't reload if we already have data
        guard !isLoading, profileDetail == nil else { return }

        isLoading = true
        error = nil

        do {
            let detail = try await postService.fetchProfileDetail(loginName: loginName, offset: 0, limit: 18)
            profileDetail = detail
            posts = detail.posts
            currentOffset = detail.pagination.offset
            hasMore = detail.pagination.hasMore
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func loadMorePosts() async {
        guard !isLoadingMore && hasMore else { return }

        isLoadingMore = true

        do {
            let detail = try await postService.fetchProfileDetail(loginName: loginName, offset: currentOffset, limit: 18)
            posts.append(contentsOf: detail.posts)
            currentOffset = detail.pagination.offset
            hasMore = detail.pagination.hasMore
        } catch {
            Logger.warning("Failed to load more posts: \(error.localizedDescription)", category: Logger.network)
        }

        isLoadingMore = false
    }

    func refresh() async {
        isLoading = true
        error = nil
        currentOffset = 0

        do {
            let detail = try await postService.fetchProfileDetail(loginName: loginName, offset: 0, limit: 18)
            profileDetail = detail
            posts = detail.posts
            currentOffset = detail.pagination.offset
            hasMore = detail.pagination.hasMore
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func toggleFollow() async {
        guard var profile = profileDetail else { return }

        do {
            if profile.user.isFollowing {
                try await postService.unfollowProfile(loginName: loginName)
            } else {
                try await postService.followProfile(loginName: loginName)
            }

            // Update the local state optimistically
            var updatedUser = profile.user
            updatedUser = ProfileUser(
                id: updatedUser.id,
                loginName: updatedUser.loginName,
                displayName: updatedUser.displayName,
                isFollowing: !updatedUser.isFollowing
            )
            profile = ProfileDetail(
                user: updatedUser,
                banner: profile.banner,
                posts: profile.posts,
                pagination: profile.pagination,
                followings: profile.followings,
                totalFollowings: profile.totalFollowings,
                links: profile.links
            )
            profileDetail = profile
        } catch {
            self.error = error.localizedDescription
        }
    }
}

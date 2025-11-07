import Foundation
import Combine

@MainActor
class FollowingListViewModel: ObservableObject {
    @Published var followings: [ProfileFollowing] = []
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

    func loadFollowings() async {
        // Don't reload if we already have data
        guard !isLoading, followings.isEmpty else { return }

        isLoading = true
        error = nil

        do {
            let response = try await postService.fetchProfileFollowings(loginName: loginName, offset: 0, limit: 50)
            followings = response.followings
            currentOffset = response.pagination.offset
            hasMore = response.pagination.hasMore
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func loadMoreFollowings() async {
        guard !isLoadingMore && hasMore else { return }

        isLoadingMore = true

        do {
            let response = try await postService.fetchProfileFollowings(loginName: loginName, offset: currentOffset, limit: 50)
            followings.append(contentsOf: response.followings)
            currentOffset = response.pagination.offset
            hasMore = response.pagination.hasMore
        } catch {
            Logger.warning("Failed to load more followings: \(error.localizedDescription)", category: Logger.network)
        }

        isLoadingMore = false
    }

    func refresh() async {
        isLoading = true
        error = nil
        currentOffset = 0

        do {
            let response = try await postService.fetchProfileFollowings(loginName: loginName, offset: 0, limit: 50)
            followings = response.followings
            currentOffset = response.pagination.offset
            hasMore = response.pagination.hasMore
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

import Foundation
import Combine

@MainActor
class CommunityDetailViewModel: ObservableObject {
    @Published var communityDetail: CommunityDetail?
    @Published var posts: [CommunityDetailPost] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var isLoadingMore = false
    @Published var error: String?
    @Published var hasMore = false

    private let postService = PostService.shared
    private var currentOffset = 0
    let slug: String

    init(slug: String) {
        self.slug = slug
    }

    func loadCommunity() async {
        Logger.debug("📥 loadCommunity called - isLoading: \(isLoading), isRefreshing: \(isRefreshing), hasData: \(communityDetail != nil)", category: Logger.network)

        // Don't reload if we already have data or if currently refreshing
        guard !isLoading, !isRefreshing, communityDetail == nil else {
            Logger.debug("⏭️ loadCommunity guard returned - skipping load", category: Logger.network)
            return
        }

        isLoading = true
        error = nil
        Logger.debug("📡 loadCommunity: Making API call", category: Logger.network)

        do {
            let detail = try await postService.fetchCommunityDetail(slug: slug, offset: 0, limit: 18)
            communityDetail = detail
            posts = detail.posts
            currentOffset = detail.pagination.offset
            hasMore = detail.pagination.hasMore
            Logger.debug("✅ loadCommunity: Success - loaded \(posts.count) posts", category: Logger.network)
        } catch {
            Logger.error("❌ loadCommunity: Failed - \(error.localizedDescription)", category: Logger.network)
            self.error = error.localizedDescription
        }

        isLoading = false
        Logger.debug("📥 loadCommunity completed - isLoading: \(isLoading)", category: Logger.network)
    }

    func loadMorePosts() async {
        guard !isLoadingMore && hasMore else { return }

        isLoadingMore = true

        do {
            let detail = try await postService.fetchCommunityDetail(slug: slug, offset: currentOffset, limit: 18)
            posts.append(contentsOf: detail.posts)
            currentOffset = detail.pagination.offset
            hasMore = detail.pagination.hasMore
        } catch {
            Logger.warning("Failed to load more posts: \(error.localizedDescription)", category: Logger.network)
        }

        isLoadingMore = false
    }

    func refresh() async {
        Logger.debug("🔄 Starting refresh for community: \(slug)", category: Logger.network)
        guard !isRefreshing else {
            Logger.debug("⚠️ Already refreshing, skipping", category: Logger.network)
            return
        }

        isRefreshing = true
        error = nil
        currentOffset = 0

        do {
            Logger.debug("📡 Calling API: fetchCommunityDetail(slug: \(slug), offset: 0, limit: 18)", category: Logger.network)
            let detail = try await postService.fetchCommunityDetail(slug: slug, offset: 0, limit: 18)

            Logger.debug("✅ API Response received:", category: Logger.network)
            Logger.debug("  - Community: \(detail.community.name) (@\(detail.community.slug))", category: Logger.network)
            Logger.debug("  - Posts count: \(detail.posts.count)", category: Logger.network)
            Logger.debug("  - Comments count: \(detail.comments.count)", category: Logger.network)
            Logger.debug("  - Stats: posts=\(detail.stats.totalPosts), contributors=\(detail.stats.totalContributors), comments=\(detail.stats.totalComments)", category: Logger.network)
            Logger.debug("  - Pagination: offset=\(detail.pagination.offset), hasMore=\(detail.pagination.hasMore)", category: Logger.network)
            Logger.debug("  - Post IDs: \(detail.posts.map { $0.id }.joined(separator: ", "))", category: Logger.network)

            communityDetail = detail
            posts = detail.posts
            currentOffset = detail.pagination.offset
            hasMore = detail.pagination.hasMore

            Logger.debug("✅ Properties updated:", category: Logger.network)
            Logger.debug("  - communityDetail set: \(communityDetail != nil)", category: Logger.network)
            Logger.debug("  - posts.count: \(posts.count)", category: Logger.network)
            Logger.debug("  - currentOffset: \(currentOffset)", category: Logger.network)
            Logger.debug("  - hasMore: \(hasMore)", category: Logger.network)
        } catch {
            Logger.error("❌ API call failed: \(error.localizedDescription)", category: Logger.network)
            self.error = error.localizedDescription
        }

        isRefreshing = false
        Logger.debug("🔄 Refresh completed for community: \(slug), isRefreshing=\(isRefreshing)", category: Logger.network)
    }
}

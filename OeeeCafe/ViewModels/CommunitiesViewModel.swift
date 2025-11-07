import Foundation
import Combine
import os.log

@MainActor
class CommunitiesViewModel: ObservableObject {
    @Published var myCommunities: [ActiveCommunity] = []
    @Published var publicCommunities: [ActiveCommunity] = []
    @Published var filteredMyCommunities: [ActiveCommunity] = []
    @Published var filteredPublicCommunities: [ActiveCommunity] = []
    @Published var searchQuery: String = "" {
        didSet {
            searchDebounceTimer?.invalidate()
            if searchQuery.isEmpty {
                // Clear search results
                searchResults = []
                isSearching = false
                filterCommunities()
            } else {
                // Start debounce timer
                searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                    Task { @MainActor in
                        await self?.performSearch()
                    }
                }
            }
        }
    }
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var isSearching = false
    @Published var searchResults: [ActiveCommunity] = []
    @Published var hasMore = true
    @Published var error: Error?

    private let communityService = CommunityService.shared
    private var searchDebounceTimer: Timer?

    func loadCommunities() async {
        isLoading = true
        error = nil

        do {
            // Load my communities
            let myCommunitiesResponse = try await communityService.getMyCommunitiesList()

            // Load first page of public communities
            let publicCommunitiesResponse = try await communityService.getPublicCommunities(offset: 0, limit: 20)

            myCommunities = myCommunitiesResponse.communities
            publicCommunities = publicCommunitiesResponse.communities
            hasMore = publicCommunitiesResponse.pagination.hasMore
            filterCommunities()
        } catch {
            Logger.error("Failed to load communities: \(error)", category: Logger.network)
            self.error = error
        }

        isLoading = false
    }

    func loadMorePublicCommunities() async {
        guard !isLoadingMore && hasMore && searchQuery.isEmpty else {
            return
        }

        isLoadingMore = true

        do {
            let offset = publicCommunities.count
            let response = try await communityService.getPublicCommunities(offset: offset, limit: 20)

            publicCommunities.append(contentsOf: response.communities)
            hasMore = response.pagination.hasMore
            filterCommunities()
        } catch {
            Logger.error("Failed to load more communities: \(error)", category: Logger.network)
            self.error = error
        }

        isLoadingMore = false
    }

    private func performSearch() async {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            return
        }

        isSearching = true

        do {
            // Server-side search for public communities
            let searchResponse = try await communityService.searchPublicCommunities(query: query, offset: 0, limit: 20)
            searchResults = searchResponse.communities

            // Client-side filter for my communities
            let normalizedQuery = query.lowercased()
            filteredMyCommunities = myCommunities.filter { community in
                community.name.lowercased().contains(normalizedQuery) ||
                community.slug.lowercased().contains(normalizedQuery) ||
                (community.description?.lowercased().contains(normalizedQuery) ?? false)
            }
        } catch {
            Logger.error("Failed to search communities: \(error)", category: Logger.network)
            self.error = error
        }

        isSearching = false
    }

    private func filterCommunities() {
        let query = searchQuery.lowercased().trimmingCharacters(in: .whitespaces)

        if query.isEmpty {
            filteredMyCommunities = myCommunities
            filteredPublicCommunities = publicCommunities
        } else {
            filteredMyCommunities = myCommunities.filter { community in
                community.name.lowercased().contains(query) ||
                community.slug.lowercased().contains(query) ||
                (community.description?.lowercased().contains(query) ?? false)
            }
            filteredPublicCommunities = publicCommunities.filter { community in
                community.name.lowercased().contains(query) ||
                community.slug.lowercased().contains(query) ||
                (community.description?.lowercased().contains(query) ?? false)
            }
        }
    }
}

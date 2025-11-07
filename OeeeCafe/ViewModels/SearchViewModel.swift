import Foundation
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var users: [SearchUser] = []
    @Published var posts: [SearchPost] = []
    @Published var isLoading = false
    @Published var error: String?

    private let searchService = SearchService.shared
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Debounce search text changes
        $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.performSearch()
                }
            }
            .store(in: &cancellables)
    }

    private func performSearch() async {
        guard !searchText.isEmpty else {
            users = []
            posts = []
            isLoading = false
            return
        }

        // Cancel previous search
        searchTask?.cancel()

        isLoading = true
        error = nil

        searchTask = Task {
            do {
                let response = try await searchService.search(query: searchText)

                guard !Task.isCancelled else { return }

                users = response.users
                posts = response.posts
            } catch is CancellationError {
                // Ignore cancellation
            } catch {
                self.error = "Search failed: \(error.localizedDescription)"
            }

            isLoading = false
        }

        await searchTask?.value
    }

    func search() async {
        // Keep this for manual search triggers if needed
        await performSearch()
    }
}

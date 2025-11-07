import Foundation
import Combine

@MainActor
class DraftsViewModel: ObservableObject {
    @Published var drafts: [DraftPost] = []
    @Published var isLoading = false
    @Published var error: String?

    private let service = DraftsService()

    func loadDrafts() async {
        isLoading = true
        error = nil

        do {
            drafts = try await service.fetchDraftPosts()
            Logger.debug("Loaded \(drafts.count) draft posts", category: Logger.app)
        } catch let err {
            Logger.error("Failed to load draft posts", error: err, category: Logger.app)
            error = "drafts.error_loading".localized
        }

        isLoading = false
    }

    func refresh() async {
        await loadDrafts()
    }
}

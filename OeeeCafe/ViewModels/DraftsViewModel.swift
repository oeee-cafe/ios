import Foundation
import Combine

@MainActor
class DraftsViewModel: ObservableObject {
    @Published var drafts: [DraftPost] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var draftToDelete: DraftPost?
    @Published var isDeleting = false

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

    func requestDelete(_ draft: DraftPost) {
        draftToDelete = draft
    }

    func confirmDelete() async {
        guard let draft = draftToDelete else { return }

        isDeleting = true
        error = nil

        do {
            try await service.deleteDraft(postId: draft.id)
            drafts.removeAll { $0.id == draft.id }
            Logger.debug("Deleted draft post \(draft.id)", category: Logger.app)
            draftToDelete = nil
        } catch let err {
            Logger.error("Failed to delete draft post", error: err, category: Logger.app)
            error = "drafts.error_deleting".localized
        }

        isDeleting = false
    }

    func cancelDelete() {
        draftToDelete = nil
    }
}

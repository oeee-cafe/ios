import Foundation
import Combine

@MainActor
class PostDetailViewModel: ObservableObject {
    @Published var post: PostDetail?
    @Published var parentPost: ChildPost?
    @Published var comments: [Comment] = []
    @Published var childPosts: [ChildPost] = []
    @Published var reactions: [ReactionCount] = []
    @Published var isLoading = false
    @Published var isLoadingComments = false
    @Published var error: String?
    @Published var commentsHasMore = false
    @Published var commentText = ""
    @Published var replyingToComment: Comment?
    @Published var isPostingComment = false

    private var commentsOffset = 0
    private let commentsLimit = 100

    private let postService = PostService.shared
    let postId: String

    init(postId: String) {
        self.postId = postId
    }

    func loadPostDetails() async {
        // Don't reload if we already have data
        guard !isLoading, post == nil else { return }

        isLoading = true
        error = nil

        do {
            let response = try await postService.fetchPostDetails(postId: postId)
            post = response.post
            parentPost = response.parentPost
            childPosts = response.childPosts
            reactions = response.reactions

            // Load comments separately
            await loadComments()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        isLoading = true
        error = nil
        commentsOffset = 0

        do {
            let response = try await postService.fetchPostDetails(postId: postId)
            post = response.post
            parentPost = response.parentPost
            childPosts = response.childPosts
            reactions = response.reactions

            // Reload comments
            comments = []
            await loadComments()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func loadComments() async {
        guard !isLoadingComments else { return }

        isLoadingComments = true

        do {
            let response = try await postService.fetchPostComments(
                postId: postId,
                offset: commentsOffset,
                limit: commentsLimit
            )

            if commentsOffset == 0 {
                comments = response.comments
            } else {
                comments.append(contentsOf: response.comments)
            }

            commentsHasMore = response.pagination.hasMore
            commentsOffset += response.comments.count
        } catch {
            self.error = error.localizedDescription
        }

        isLoadingComments = false
    }

    func loadMoreComments() async {
        guard commentsHasMore, !isLoadingComments else { return }
        await loadComments()
    }

    func setReplyTarget(_ comment: Comment) {
        replyingToComment = comment
    }

    func cancelReply() {
        replyingToComment = nil
    }

    func postComment() async {
        guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isPostingComment else { return }

        isPostingComment = true
        error = nil

        do {
            let _ = try await postService.postComment(
                postId: postId,
                content: commentText,
                parentCommentId: replyingToComment?.id
            )

            // Clear comment text and reply target
            commentText = ""
            replyingToComment = nil

            // Reload comments to show the new comment
            commentsOffset = 0
            comments = []
            await loadComments()
        } catch {
            self.error = error.localizedDescription
        }

        isPostingComment = false
    }

    func deletePost() async throws {
        try await postService.deletePost(postId: postId)
    }

    func toggleReaction(emoji: String) async {
        do {
            let reaction = reactions.first(where: { $0.emoji == emoji })
            let response: ReactionResponse

            if reaction?.reactedByUser == true {
                // Remove reaction
                response = try await postService.removeReaction(postId: postId, emoji: emoji)
            } else {
                // Add reaction
                response = try await postService.addReaction(postId: postId, emoji: emoji)
            }

            // Update reactions with response
            reactions = response.reactions
        } catch {
            self.error = error.localizedDescription
        }
    }
}

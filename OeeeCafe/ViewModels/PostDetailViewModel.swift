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

            let filteredComments = response.comments.compactMap { filterComment($0) }

            if commentsOffset == 0 {
                comments = filteredComments
            } else {
                comments.append(contentsOf: filteredComments)
            }

            commentsHasMore = response.pagination.hasMore
            commentsOffset += response.comments.count
        } catch {
            self.error = error.localizedDescription
        }

        isLoadingComments = false
    }

    private func filterComment(_ comment: Comment) -> Comment? {
        // Filter children recursively
        let filteredChildren = comment.children.compactMap { filterComment($0) }

        // Create a new comment with filtered children
        let updatedComment = Comment(
            id: comment.id,
            postId: comment.postId,
            parentCommentId: comment.parentCommentId,
            actorId: comment.actorId,
            content: comment.content,
            contentHtml: comment.contentHtml,
            actorName: comment.actorName,
            actorHandle: comment.actorHandle,
            actorLoginName: comment.actorLoginName,
            isLocal: comment.isLocal,
            createdAt: comment.createdAt,
            updatedAt: comment.updatedAt,
            deletedAt: comment.deletedAt,
            children: filteredChildren
        )

        // Return nil if this comment should not be displayed
        return updatedComment.shouldDisplay ? updatedComment : nil
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

    func deleteComment(_ comment: Comment) async {
        error = nil

        do {
            try await postService.deleteComment(commentId: comment.id)

            // Reload comments to show the deleted state
            commentsOffset = 0
            comments = []
            await loadComments()
        } catch {
            self.error = error.localizedDescription
        }
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

    func reportPost(description: String) async throws {
        try await postService.reportPost(postId: postId, description: description)
    }
}

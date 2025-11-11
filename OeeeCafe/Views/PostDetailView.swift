import SwiftUI
import Kingfisher

struct PostDetailView: View {
    @StateObject private var viewModel: PostDetailViewModel
    @State private var showingReactors: ReactionSheet?
    @State private var showingDeleteConfirmation = false
    @State private var showingCommentDeleteConfirmation = false
    @State private var commentToDelete: Comment?
    @State private var isDeleting = false
    @State private var isDeletingComment = false
    @State private var showDimensionPicker = false
    @State private var showOrientationPicker = false
    @State private var canvasDimensions: CanvasDimensions?
    @State private var draftPostToPublish: DraftPostIdentifier?
    @State private var showLogin = false
    @State private var showReplay = false
    @State private var showMoveSheet = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService

    init(postId: String) {
        _viewModel = StateObject(wrappedValue: PostDetailViewModel(postId: postId))
    }

    var body: some View {
        ScrollView {
            contentView
        }
        .navigationTitle("nav.post_details".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .alert("post.delete_title".localized, isPresented: $showingDeleteConfirmation) {
            Button("common.cancel".localized, role: .cancel) { }
            Button("post.delete_button".localized, role: .destructive) {
                Task {
                    isDeleting = true
                    do {
                        try await viewModel.deletePost()
                        dismiss()
                    } catch {
                        viewModel.error = error.localizedDescription
                        isDeleting = false
                    }
                }
            }
        } message: {
            Text("post.delete_message".localized)
        }
        .alert("post.delete_comment_title".localized, isPresented: $showingCommentDeleteConfirmation) {
            Button("common.cancel".localized, role: .cancel) {
                commentToDelete = nil
            }
            Button("common.delete".localized, role: .destructive) {
                if let comment = commentToDelete {
                    Task {
                        isDeletingComment = true
                        await viewModel.deleteComment(comment)
                        isDeletingComment = false
                        commentToDelete = nil
                    }
                }
            }
        } message: {
            Text("post.delete_comment_message".localized)
        }
        .sheet(item: $showingReactors) { reactionSheet in
            ReactorsListView(postId: reactionSheet.postId, emoji: reactionSheet.emoji)
        }
        .sheet(isPresented: $showLogin) {
            NavigationView {
                LoginView()
            }
        }
        .sheet(isPresented: $showMoveSheet) {
            if let post = viewModel.post {
                MovePostSheet(postId: post.id)
            }
        }
        .fullScreenCover(isPresented: $showReplay) {
            if let post = viewModel.post {
                ReplayWebView(postId: post.id)
            }
        }
        .sheet(isPresented: $showDimensionPicker) {
            CanvasDimensionPicker(
                onDimensionsSelected: { width, height, tool in
                    showDimensionPicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        canvasDimensions = CanvasDimensions(width: width, height: height, tool: tool)
                    }
                },
                onCancel: {
                    showDimensionPicker = false
                },
                backgroundColor: nil,
                foregroundColor: nil
            )
        }
        .sheet(isPresented: $showOrientationPicker) {
            OrientationPicker(
                onOrientationSelected: { width, height in
                    showOrientationPicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        canvasDimensions = CanvasDimensions(width: width, height: height, tool: .neoCucumberOffline)
                    }
                },
                onCancel: {
                    showOrientationPicker = false
                }
            )
        }
        .fullScreenCover(item: $canvasDimensions) { dimensions in
            if let parentPostId = viewModel.post?.id {
                DrawWebView(
                    width: dimensions.width,
                    height: dimensions.height,
                    tool: dimensions.tool,
                    communityId: viewModel.post?.community?.id,
                    parentPostId: parentPostId
                ) { postId, communityId, imageUrl in
                    Logger.debug("Drawing completed: postId=\(postId), communityId=\(communityId ?? "nil"), imageUrl=\(imageUrl)", category: Logger.app)
                    draftPostToPublish = DraftPostIdentifier(
                        postId: postId,
                        communityId: communityId,
                        imageUrl: imageUrl
                    )
                    canvasDimensions = nil
                }
            }
        }
        .sheet(item: $draftPostToPublish) { draft in
            DraftPostView(
                postId: draft.postId,
                communityId: draft.communityId,
                imageUrl: draft.imageUrl,
                onPublished: {
                    draftPostToPublish = nil
                    // Refresh the current post view to show published state
                    Task {
                        await viewModel.refresh()
                    }
                },
                onCancel: {
                    draftPostToPublish = nil
                }
            )
        }
        .refreshable {
            await Task { @MainActor in
                await viewModel.refresh()
            }.value
        }
        .task {
            await viewModel.loadPostDetails()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.post == nil {
            LoadingStateView(message: "post.loading".localized)
                .padding(.top, 100)
        } else if let error = viewModel.error, viewModel.post == nil {
            ErrorStateView(error: error) {
                Task {
                    await viewModel.loadPostDetails()
                }
            }
            .padding(.top, 100)
        } else if let post = viewModel.post {
            VStack(alignment: .leading, spacing: 16) {
                    // Parent Post (Replying To)
                    if let parentPost = viewModel.parentPost {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("post.replying_to".localized)
                                .font(.headline)
                                .padding(.horizontal)

                            NavigationLink(destination: PostDetailView(postId: parentPost.id)) {
                                ChildPostCard(childPost: parentPost)
                                    .padding(.horizontal)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 8)
                    }

                    // Image
                    KFImage(URL(string: post.image.url))
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .aspectRatio(CGFloat(post.image.width) / CGFloat(post.image.height), contentMode: .fit)
                                .overlay {
                                    ProgressView()
                                }
                        }
                        .onFailure { error in
                            // Error handling - Kingfisher will display placeholder
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fit)

                // Details
                VStack(alignment: .leading, spacing: 12) {
                    if let title = post.title {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }

                    if let content = post.content, !content.isEmpty {
                        Text(content)
                            .font(.body)
                            .foregroundColor(.primary)
                    }

                    // Hashtags
                    if !post.hashtags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(post.hashtags, id: \.self) { hashtag in
                                    Text("#\(hashtag)")
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }

                    NavigationLink {
                        ProfileView(loginName: post.author.loginName)
                    } label: {
                        HStack {
                            Image(systemName: "person.circle")
                            Text(post.author.loginName)
                                .font(.subheadline)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                    }

                    // Community (only show if post has community)
                    if let community = post.community {
                        NavigationLink {
                            CommunityDetailView(slug: community.slug)
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.stack")
                                Text(community.name)
                                    .font(.subheadline)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .foregroundColor(.primary)
                        }
                    }

                    Divider()

                    HStack(spacing: 24) {
                        Label(post.image.paintDuration, systemImage: "clock")
                        Label("\(post.viewerCount)", systemImage: "eye")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    if let publishedAt = post.publishedAt {
                        Text("post.published".localized(publishedAt.relativeFormatted()))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Reactions Section
                    if !viewModel.reactions.isEmpty {
                        Divider()
                            .padding(.vertical, 8)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.reactions, id: \.emoji) { reaction in
                                    Button(action: {
                                        if authService.isAuthenticated {
                                            Task {
                                                await viewModel.toggleReaction(emoji: reaction.emoji)
                                            }
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Text(reaction.emoji)
                                                .font(.title3)
                                            if reaction.count > 0 {
                                                Text("\(reaction.count)")
                                                    .font(.subheadline)
                                                    .fontWeight(reaction.reactedByUser ? .bold : .regular)
                                                    .foregroundColor(reaction.reactedByUser ? .blue : .secondary)
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(reaction.reactedByUser ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                        .cornerRadius(16)
                                        .opacity(!authService.isAuthenticated && reaction.count == 0 ? 0.5 : 1.0)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .simultaneousGesture(
                                        LongPressGesture(minimumDuration: 0.5)
                                            .onEnded { _ in
                                                if reaction.count > 0 {
                                                    showingReactors = ReactionSheet(emoji: reaction.emoji, postId: viewModel.postId)
                                                }
                                            }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding()

                // Child Posts (Replies)
                if !viewModel.childPosts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("post.replies".localized(viewModel.childPosts.count))
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(viewModel.childPosts) { childPost in
                            NavigationLink(destination: PostDetailView(postId: childPost.id)) {
                                ChildPostCard(childPost: childPost)
                                    .padding(.horizontal)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Comments Section
                if !viewModel.comments.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("post.comments".localized(viewModel.comments.count))
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(viewModel.comments) { comment in
                            CommentCard(
                                comment: comment,
                                currentUserLoginName: authService.currentUser?.loginName,
                                onReply: { comment in
                                    viewModel.setReplyTarget(comment)
                                },
                                onDelete: { comment in
                                    commentToDelete = comment
                                    showingCommentDeleteConfirmation = true
                                }
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Comment Input Section (only show if logged in)
                if authService.isAuthenticated {
                    VStack(alignment: .leading, spacing: 12) {
                        Divider()
                            .padding(.horizontal)

                        // Reply indicator
                        if let replyingTo = viewModel.replyingToComment {
                            HStack {
                                Text("post.replying_to_user".localized(replyingTo.actorName))
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Button(action: {
                                    viewModel.cancelReply()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                        }

                        // Comment input
                        HStack(alignment: .top, spacing: 12) {
                            TextEditor(text: $viewModel.commentText)
                                .frame(minHeight: 60, maxHeight: 120)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )

                            Button(action: {
                                Task {
                                    await viewModel.postComment()
                                }
                            }) {
                                if viewModel.isPostingComment {
                                    ProgressView()
                                        .frame(width: 44, height: 44)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.title3)
                                        .foregroundColor(viewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                                }
                            }
                            .disabled(viewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isPostingComment)
                            .frame(width: 44, height: 44)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            // Share button - always visible
            if let post = viewModel.post {
                let slug = post.community?.slug ?? post.author.loginName
                if let shareURL = URL(string: "https://oeee.cafe/@\(slug)/\(post.id)") {
                    ShareLink(item: shareURL) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                    }
                }
            }

            // Menu with other actions
            if let post = viewModel.post {
                Menu {
                    // Replay button - hide for neo-cucumber posts
                    if post.image.tool != "neo-cucumber" {
                        Button(action: {
                            if authService.isAuthenticated {
                                showReplay = true
                            } else {
                                showLogin = true
                            }
                        }) {
                            Label("Replay", systemImage: "play.rectangle")
                        }
                    }

                    // Reply button
                    Button(action: {
                        if let community = post.community,
                           let backgroundColor = community.backgroundColor,
                           let foregroundColor = community.foregroundColor {
                            // Two-tone community: show orientation picker
                            showOrientationPicker = true
                        } else {
                            showDimensionPicker = true
                        }
                    }) {
                        Label("Reply", systemImage: "arrowshape.turn.up.left.2")
                    }

                    // Move to Community button - only visible to post owner
                    if let currentUser = authService.currentUser,
                       post.author.id == currentUser.id {
                        Button(action: {
                            showMoveSheet = true
                        }) {
                            Label("post.move_to_community".localized, systemImage: "folder")
                        }
                    }

                    // Delete button - only visible to post owner
                    if let currentUser = authService.currentUser,
                       post.author.id == currentUser.id {
                        Button(role: .destructive, action: {
                            showingDeleteConfirmation = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                        .disabled(isDeleting)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
        }
    }
}

// Helper struct for sheet presentation
struct ReactionSheet: Identifiable {
    let emoji: String
    let postId: String

    var id: String { "\(postId)-\(emoji)" }
}

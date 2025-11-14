import SwiftUI
import Kingfisher

struct CommunityDetailView: View {
    @StateObject private var viewModel: CommunityDetailViewModel
    @State private var showDimensionPicker = false
    @State private var showOrientationPicker = false
    @State private var showEditCommunity = false
    @State private var canvasDimensions: CanvasDimensions?
    @State private var draftPostToPublish: DraftPostIdentifier?
    @State private var navigateToPost: String?
    @State private var shouldNavigateToPost = false
    @State private var shouldNavigateBack = false
    @ObservedObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss

    private let columns = Constants.postGridColumns

    init(slug: String) {
        _viewModel = StateObject(wrappedValue: CommunityDetailViewModel(slug: slug))
    }

    private var isOwner: Bool {
        guard let userId = authService.currentUser?.id,
              let ownerId = viewModel.communityDetail?.community.ownerId else {
            return false
        }
        return userId == ownerId
    }

    private var canViewMembers: Bool {
        // Members button only shows for private communities
        guard let detail = viewModel.communityDetail else {
            return false
        }
        return authService.isAuthenticated && detail.community.visibility == "private"
    }

    @State private var isOwnerOrModerator: Bool = false
    @State private var hasCheckedRole: Bool = false

    var body: some View {
        ScrollView {
            contentView
        }
        .navigationTitle(viewModel.communityDetail?.community.name ?? "nav.community_default".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // New post button - always visible
                if viewModel.communityDetail != nil {
                    Button(action: {
                        // If community has defined colors, show orientation picker
                        if let community = viewModel.communityDetail?.community,
                           community.backgroundColor != nil && community.foregroundColor != nil {
                            showOrientationPicker = true
                        } else {
                            showDimensionPicker = true
                        }
                    }) {
                        Image(systemName: "square.and.pencil")
                            .font(.title3)
                    }
                }

                // Menu with other actions
                if viewModel.communityDetail != nil {
                    Menu {
                        // Members button - visible to authenticated users
                        if canViewMembers {
                            NavigationLink(destination: CommunityMembersView(
                                slug: viewModel.slug,
                                isOwner: isOwner,
                                isOwnerOrModerator: isOwnerOrModerator,
                                onLeave: {
                                    shouldNavigateBack = true
                                }
                            )) {
                                Label("Members", systemImage: "person.2")
                            }
                        }

                        // Settings button - visible to owner only
                        if isOwner {
                            Button(action: {
                                showEditCommunity = true
                            }) {
                                Label("Settings", systemImage: "gear")
                            }
                        }

                        // Share button - visible for public communities only
                        if let detail = viewModel.communityDetail,
                           detail.community.visibility != "private",
                           let shareURL = URL(string: "https://oeee.cafe/communities/@\(viewModel.slug)") {
                            ShareLink(item: shareURL) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
        }
        .refreshable {
            await Task { @MainActor in
                await viewModel.refresh()
            }.value
        }
        .task {
            await viewModel.loadCommunity()
        }
        .task(id: viewModel.communityDetail?.community.id) {
            // Check moderator role from member list
            await checkUserRole()
        }
        .sheet(isPresented: $showDimensionPicker) {
            CanvasDimensionPicker(
                onDimensionsSelected: { width, height, tool in
                    showDimensionPicker = false
                    // Use a small delay to ensure the sheet is dismissed before showing fullScreenCover
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        canvasDimensions = CanvasDimensions(width: width, height: height, tool: tool)
                    }
                },
                onCancel: {
                    showDimensionPicker = false
                },
                backgroundColor: viewModel.communityDetail?.community.backgroundColor,
                foregroundColor: viewModel.communityDetail?.community.foregroundColor
            )
        }
        .sheet(isPresented: $showOrientationPicker) {
            OrientationPicker(
                onOrientationSelected: { width, height in
                    showOrientationPicker = false
                    // Use a small delay to ensure the sheet is dismissed before showing fullScreenCover
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
            if let communityId = viewModel.communityDetail?.community.id {
                DrawWebView(
                    width: dimensions.width,
                    height: dimensions.height,
                    tool: dimensions.tool,
                    communityId: communityId
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
                    navigateToPost = draft.postId
                    shouldNavigateToPost = true
                },
                onDeleted: {
                    draftPostToPublish = nil
                },
                onCancel: {
                    draftPostToPublish = nil
                }
            )
        }
        .navigationDestination(isPresented: $shouldNavigateToPost) {
            if let postId = navigateToPost {
                PostDetailView(postId: postId)
            }
        }
        .sheet(isPresented: $showEditCommunity, onDismiss: {
            // If community was deleted, navigate back; otherwise refresh
            if shouldNavigateBack {
                dismiss()
            } else {
                Task {
                    await viewModel.refresh()
                }
            }
        }) {
            if let detail = viewModel.communityDetail {
                NavigationView {
                    EditCommunityView(
                        slug: viewModel.slug,
                        communityInfo: CommunityInfo(
                            id: detail.community.id,
                            name: detail.community.name,
                            slug: detail.community.slug,
                            description: detail.community.description,
                            visibility: detail.community.visibility,
                            ownerId: detail.community.ownerId,
                            backgroundColor: detail.community.backgroundColor,
                            foregroundColor: detail.community.foregroundColor
                        ),
                        onCommunityDeleted: {
                            shouldNavigateBack = true
                        }
                    )
                }
            }
        }
        .onChange(of: shouldNavigateBack) { oldValue, newValue in
            if newValue {
                dismiss()
            }
        }
    }

    private func checkUserRole() async {
        guard let userId = authService.currentUser?.id,
              viewModel.communityDetail != nil,
              !hasCheckedRole else {
            return
        }

        // Start with owner check
        isOwnerOrModerator = isOwner

        // Only check members for private communities
        guard viewModel.communityDetail?.community.visibility == "private" else {
            hasCheckedRole = true
            return
        }

        do {
            let response = try await CommunityService.shared.getCommunityMembers(slug: viewModel.slug)
            if let userMember = response.members.first(where: { $0.userId == userId }) {
                isOwnerOrModerator = ["owner", "moderator"].contains(userMember.role)
            }
            hasCheckedRole = true
        } catch {
            // If we can't fetch members, fall back to owner check
            isOwnerOrModerator = isOwner
            hasCheckedRole = true
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.communityDetail == nil {
                LoadingStateView(message: "community.loading".localized)
                    .padding(.top, 100)
            } else if let error = viewModel.error, viewModel.communityDetail == nil {
                ErrorStateView(error: error) {
                    Task {
                        await viewModel.loadCommunity()
                    }
                }
                .padding(.top, 100)
            } else if let detail = viewModel.communityDetail {
                VStack(alignment: .leading, spacing: 24) {
                    // Community Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(detail.community.name)
                            .font(.title)
                            .fontWeight(.bold)

                        Text("@\(detail.community.slug)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if let description = detail.community.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Stats Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("community.stats".localized)
                            .font(.headline)
                            .fontWeight(.semibold)

                        HStack(spacing: 24) {
                            Spacer()
                            StatItem(label: "community.stat_posts".localized, value: "\(detail.stats.totalPosts)")
                            Spacer()
                            StatItem(label: "community.stat_contributors".localized, value: "\(detail.stats.totalContributors)")
                            Spacer()
                            StatItem(label: "community.stat_comments".localized, value: "\(detail.stats.totalComments)")
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(0)

                    // Recent Comments
                    if !detail.comments.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("community.recent_comments".localized)
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            ForEach(detail.comments) { comment in
                                RecentCommentCard(comment: comment)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    // Recent Posts
                    if !viewModel.posts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("community.recent_posts".localized)
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(Array(viewModel.posts.enumerated()), id: \.element.id) { index, post in
                                    NavigationLink(destination: PostDetailView(postId: post.id)) {
                                        CommunityDetailPostItem(post: post)
                                    }
                                    .buttonStyle(.plain)
                                    .onAppear {
                                        if index == viewModel.posts.count - 1 && viewModel.hasMore && !viewModel.isLoadingMore {
                                            Task {
                                                await viewModel.loadMorePosts()
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 8)

                            // Loading more indicator
                            if viewModel.isLoadingMore {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                                .padding()
                            }
                        }
                    }
                }
                .padding(.bottom)
            }
    }
}

struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct CommunityDetailPostItem: View {
    let post: CommunityDetailPost

    var body: some View {
        AsyncImageGrid(imageUrl: post.imageUrl)
    }
}

#Preview {
    NavigationView {
        CommunityDetailView(slug: "test")
    }
}

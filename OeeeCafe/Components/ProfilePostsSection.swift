import SwiftUI

struct ProfilePostsSection: View {
    let posts: [ProfilePost]
    let isLoadingMore: Bool
    let hasMore: Bool
    let onLoadMore: () async -> Void

    private let columns = Constants.postGridColumns

    var body: some View {
        if !posts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("profile.posts".localized(posts.count))
                    .font(.headline)
                    .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(posts.enumerated()), id: \.element.id) { index, post in
                        NavigationLink(destination: PostDetailView(postId: post.id)) {
                            ProfilePostGridItem(post: post)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            if index == posts.count - 1 && hasMore && !isLoadingMore {
                                Task {
                                    await onLoadMore()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)

                // Loading more indicator
                if isLoadingMore {
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
}

import SwiftUI

struct SearchPostResultsGrid: View {
    let posts: [SearchPost]

    private let columns = Constants.postGridColumns

    var body: some View {
        if !posts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("search.posts_count".localized(posts.count))
                    .font(.headline)
                    .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(posts) { post in
                        NavigationLink(destination: PostDetailView(postId: post.id)) {
                            SearchPostGridItem(post: post)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.top)
        }
    }
}

struct SearchPostGridItem: View {
    let post: SearchPost

    var body: some View {
        AsyncImageGrid(imageUrl: post.imageUrl, applyBlur: post.isSensitive)
    }
}

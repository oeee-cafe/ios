import SwiftUI
import Kingfisher

struct ChildPostCard: View {
    let childPost: ChildPost
    let depth: Int

    init(childPost: ChildPost, depth: Int = 0) {
        self.childPost = childPost
        self.depth = depth
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                // Thumbnail
                KFImage(URL(string: childPost.image.url))
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay {
                                ProgressView()
                            }
                    }
                    .onFailure { error in
                        // Error handling - Kingfisher will display placeholder
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(8)

                // Details
                VStack(alignment: .leading, spacing: 4) {
                    if let title = childPost.title {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                    }

                    Text("by \(childPost.author.loginName)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        Label("\(childPost.commentsCount)", systemImage: "bubble.left")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        if let publishedAt = childPost.publishedAt {
                            Text(publishedAt.relativeFormatted())
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)

            // Render children with increased depth
            if !childPost.children.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(childPost.children) { child in
                        NavigationLink(destination: PostDetailView(postId: child.id)) {
                            ChildPostCard(childPost: child, depth: depth + 1)
                                .padding(.leading, 20)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

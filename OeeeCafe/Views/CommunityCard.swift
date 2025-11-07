import SwiftUI
import Kingfisher

struct CommunityCard: View {
    let community: ActiveCommunity

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Community Header
            VStack(alignment: .leading, spacing: 4) {
                NavigationLink(destination: CommunityDetailView(slug: community.slug)) {
                    HStack {
                        Text(community.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)

                if let description = community.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 16) {
                    if let postsCount = community.postsCount {
                        Label("\(postsCount)", systemImage: "photo.stack")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    if let membersCount = community.membersCount {
                        Label("\(membersCount)", systemImage: "person.2")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)

            // Recent Posts Grid
            if !community.recentPosts.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(community.recentPosts) { post in
                            NavigationLink(destination: PostDetailView(postId: post.id)) {
                                CommunityPostThumbnail(post: post)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct CommunityPostThumbnail: View {
    let post: CommunityPost

    var body: some View {
        GeometryReader { geometry in
            KFImage(URL(string: post.imageUrl))
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
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .blur(radius: post.isSensitive ? 20 : 0)
        }
        .aspectRatio(1.0, contentMode: .fit)
        .frame(width: 100, height: 100)
        .cornerRadius(8)
    }
}

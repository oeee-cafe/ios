import SwiftUI
import Kingfisher

struct RecentCommentCard: View {
    let comment: RecentComment

    private var profileLoginName: String? {
        if comment.isLocal, let loginName = comment.actorLoginName {
            return loginName
        }
        return nil
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Post Thumbnail - navigates to post
            if let imageUrl = comment.postImageUrl {
                NavigationLink(destination: PostDetailView(postId: comment.postId)) {
                    KFImage(URL(string: imageUrl))
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                                .overlay {
                                    ProgressView()
                                }
                        }
                        .onFailure { error in
                            // Error handling - Kingfisher will display placeholder
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            // Comment Content
            VStack(alignment: .leading, spacing: 4) {
                if let loginName = profileLoginName {
                    NavigationLink(destination: ProfileView(loginName: loginName)) {
                        HStack(spacing: 4) {
                            Text(comment.actorName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text("@\(loginName)")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack(spacing: 4) {
                        Text(comment.actorName)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(comment.actorHandle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Text(comment.displayText)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(3)

                HStack {
                    if let postTitle = comment.postTitle {
                        NavigationLink(destination: PostDetailView(postId: comment.postId)) {
                            Text("on \"\(postTitle)\"")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    Text(comment.formattedCreatedAt)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

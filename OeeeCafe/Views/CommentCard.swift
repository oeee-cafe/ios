import SwiftUI

struct CommentCard: View {
    let comment: Comment
    let depth: Int = 0
    let onReply: ((Comment) -> Void)?

    private var profileLoginName: String? {
        if comment.isLocal, let loginName = comment.actorLoginName {
            return loginName
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main comment
            HStack(alignment: .top) {
                Image(systemName: "person.circle.fill")
                    .font(.title3)
                    .foregroundColor(.gray)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if let loginName = profileLoginName {
                            NavigationLink(destination: ProfileView(loginName: loginName)) {
                                HStack(spacing: 4) {
                                    Text(loginName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)

                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text(comment.actorName)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            if !comment.isLocal {
                                Text("@\(comment.actorHandle)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Text(comment.createdAt.relativeFormatted())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(comment.displayText)
                        .font(.body)

                    // Reply button
                    if let onReply = onReply {
                        Button(action: { onReply(comment) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrowshape.turn.up.left")
                                    .font(.caption)
                                Text("Reply")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)

            // Nested replies
            if !comment.children.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(comment.children) { child in
                        ThreadedCommentView(comment: child, depth: depth + 1, onReply: onReply)
                    }
                }
                .padding(.leading, 20)
                .padding(.top, 8)
            }
        }
    }
}

// Separate view for threaded comments with depth
struct ThreadedCommentView: View {
    let comment: Comment
    let depth: Int
    let onReply: ((Comment) -> Void)?

    private var profileLoginName: String? {
        if comment.isLocal, let loginName = comment.actorLoginName {
            return loginName
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main comment with border
            HStack(alignment: .top, spacing: 0) {
                // Thread line indicator
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2)
                    .padding(.trailing, 12)

                HStack(alignment: .top) {
                    Image(systemName: "person.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            if let loginName = profileLoginName {
                                NavigationLink(destination: ProfileView(loginName: loginName)) {
                                    HStack(spacing: 4) {
                                        Text(loginName)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)

                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            } else {
                                Text(comment.actorName)
                                    .font(.caption)
                                    .fontWeight(.semibold)

                                if !comment.isLocal {
                                    Text("@\(comment.actorHandle)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Text(comment.createdAt.relativeFormatted())
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Text(comment.displayText)
                            .font(.callout)

                        // Reply button
                        if let onReply = onReply {
                            Button(action: { onReply(comment) }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrowshape.turn.up.left")
                                        .font(.caption2)
                                    Text("Reply")
                                        .font(.caption2)
                                }
                                .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 2)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }

            // Nested replies
            if !comment.children.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(comment.children) { child in
                        ThreadedCommentView(comment: child, depth: depth + 1, onReply: onReply)
                    }
                }
                .padding(.leading, 20)
                .padding(.top, 8)
            }
        }
    }
}

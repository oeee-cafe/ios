import SwiftUI
import Kingfisher

struct NotificationCard: View {
    let notification: NotificationItem
    let onMarkRead: () -> Void
    let onDelete: () -> Void

    @EnvironmentObject var authService: AuthService

    var body: some View {
        Group {
            if let postId = notification.postId {
                NavigationLink(destination: PostDetailView(postId: postId)) {
                    cardContent
                }
                .simultaneousGesture(TapGesture().onEnded {
                    // Mark as read when tapped
                    if !notification.isRead {
                        onMarkRead()
                    }
                })
            } else {
                cardContent
            }
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("common.delete".localized, systemImage: "trash")
            }

            if !notification.isRead {
                Button(action: onMarkRead) {
                    Label("notifications.mark_read".localized, systemImage: "envelope.open")
                }
                .tint(.blue)
            }
        }
        .contextMenu {
            if !notification.isRead {
                Button(action: onMarkRead) {
                    Label("notifications.mark_as_read".localized, systemImage: "envelope.open")
                }
            }

            Button(role: .destructive, action: onDelete) {
                Label("common.delete".localized, systemImage: "trash")
            }
        }
    }

    private var cardContent: some View {
        HStack(alignment: .top, spacing: 12) {
            // Read indicator
            Circle()
                .fill(notification.isRead ? Color.clear : Color.blue)
                .frame(width: 8, height: 8)
                .padding(.top, 8)

            // Post thumbnail (if available)
            if let imageUrl = notification.postImageUrl {
                KFImage(URL(string: imageUrl))
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                            .overlay {
                                ProgressView()
                                    .scaleEffect(0.7)
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

            VStack(alignment: .leading, spacing: 8) {
                // Actor info
                HStack(spacing: 4) {
                    Text(notification.actorName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(notification.actorHandle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Notification message
                Text(notification.displayText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                // Context (comment text or guestbook content)
                if let commentContent = notification.commentContent {
                    Text(commentContent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                } else if let guestbookContent = notification.guestbookContent {
                    Text(guestbookContent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }

                // Time ago
                Text(notification.timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(notification.isRead ? Color.clear : Color.blue.opacity(0.05))
    }
}

#Preview {
    let sampleNotification = NotificationItem(
        id: "1",
        recipientId: "2",
        actorId: "3",
        actorName: "John Doe",
        actorHandle: "@john@example.com",
        notificationType: .comment,
        postId: "4",
        commentId: "5",
        reactionIri: nil,
        reactionEmoji: nil,
        guestbookEntryId: nil,
        readAt: nil,
        createdAt: Date().addingTimeInterval(-3600),
        postTitle: "My awesome post",
        postAuthorLoginName: "jane",
        postImageFilename: nil,
        postImageUrl: nil,
        postImageWidth: nil,
        postImageHeight: nil,
        commentContent: "This is a great post!",
        commentContentHtml: "<p>This is a great post!</p>",
        guestbookContent: nil
    )

    NotificationCard(
        notification: sampleNotification,
        onMarkRead: {},
        onDelete: {}
    )
    .environmentObject(AuthService.shared)
}

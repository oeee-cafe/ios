import Foundation

// MARK: - Notification Type
enum NotificationType: String, Codable {
    case comment = "Comment"
    case reaction = "Reaction"
    case follow = "Follow"
    case guestbookEntry = "GuestbookEntry"
    case guestbookReply = "GuestbookReply"
    case mention = "Mention"
    case postReply = "PostReply"
}

// MARK: - Notification
struct NotificationItem: Codable, Identifiable {
    let id: String
    let recipientId: String
    let actorId: String
    let actorName: String
    let actorHandle: String
    let notificationType: NotificationType
    let postId: String?
    let commentId: String?
    let reactionIri: String?
    let reactionEmoji: String?
    let guestbookEntryId: String?
    let readAt: Date?
    let createdAt: Date

    // Post context
    let postTitle: String?
    let postAuthorLoginName: String?
    let postImageFilename: String?
    let postImageUrl: String?
    let postImageWidth: Int?
    let postImageHeight: Int?

    // Comment context
    let commentContent: String?
    let commentContentHtml: String?

    // Guestbook context
    let guestbookContent: String?

    var isRead: Bool {
        readAt != nil
    }

    // Format notification text for display
    var displayText: String {
        switch notificationType {
        case .comment:
            return "\(actorName) commented on your post"
        case .reaction:
            if let emoji = reactionEmoji {
                return "\(actorName) reacted with \(emoji) to your post"
            }
            return "\(actorName) reacted to your post"
        case .follow:
            return "\(actorName) started following you"
        case .postReply:
            return "\(actorName) replied to your post"
        case .guestbookEntry:
            return "\(actorName) wrote in your guestbook"
        case .guestbookReply:
            return "\(actorName) replied to your guestbook entry"
        case .mention:
            return "\(actorName) mentioned you in a comment"
        }
    }

    // Get relative time string
    var timeAgo: String {
        createdAt.relativeFormatted()
    }
}

// MARK: - Notifications Response
struct NotificationsResponse: Codable {
    let notifications: [NotificationItem]
    let total: Int
    let hasMore: Bool
}

// MARK: - Unread Count Response
struct UnreadCountResponse: Codable {
    let count: Int
}

// MARK: - Mark Read Response
struct MarkReadResponse: Codable {
    let success: Bool
    let notification: NotificationItem?
}

// MARK: - Delete Response
struct DeleteNotificationResponse: Codable {
    let success: Bool
}

// MARK: - Mark All Read Response
struct MarkAllReadResponse: Codable {
    let success: Bool
    let count: Int
}

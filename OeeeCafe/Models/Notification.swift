import Foundation

// MARK: - Notification Type
enum NotificationType: String, Codable {
    case comment = "Comment"
    case commentReply = "CommentReply"
    case reaction = "Reaction"
    case follow = "Follow"
    case guestbookEntry = "GuestbookEntry"
    case guestbookReply = "GuestbookReply"
    case mention = "Mention"
    case postReply = "PostReply"
    case unknown = "Unknown"

    // Custom decoder to handle unknown notification types
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        // Try to initialize with the raw value, default to .unknown if not recognized
        self = NotificationType(rawValue: rawValue) ?? .unknown
    }
}

// MARK: - Notification
struct NotificationItem: Codable, Identifiable {
    let id: String
    let recipientId: String
    let actorId: String
    let actorName: String
    let actorHandle: String
    let actorLoginName: String?
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
            return "notification.comment".localized(actorName)
        case .commentReply:
            return "notification.comment_reply".localized(actorName)
        case .reaction:
            if let emoji = reactionEmoji {
                return "notification.reaction_emoji".localized(actorName, emoji)
            }
            return "notification.reaction".localized(actorName)
        case .follow:
            return "notification.follow".localized(actorName)
        case .postReply:
            return "notification.post_reply".localized(actorName)
        case .guestbookEntry:
            return "notification.guestbook_entry".localized(actorName)
        case .guestbookReply:
            return "notification.guestbook_reply".localized(actorName)
        case .mention:
            return "notification.mention".localized(actorName)
        case .unknown:
            return "notification.comment".localized(actorName)
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
    let notification: NotificationItem
}

// MARK: - Mark All Read Response
struct MarkAllReadResponse: Codable {
    let count: Int
}

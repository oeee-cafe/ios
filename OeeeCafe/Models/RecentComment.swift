import Foundation
import UIKit

struct RecentComment: Identifiable, Codable {
    let id: String
    let postId: String
    let actorId: String
    let content: String
    let contentHtml: String?
    let actorName: String
    let actorHandle: String
    let actorLoginName: String?
    let isLocal: Bool
    let createdAt: Date
    let postTitle: String?
    let postAuthorLoginName: String
    let postImageUrl: String?
    let postImageWidth: Int?
    let postImageHeight: Int?

    var displayText: String {
        if let html = contentHtml {
            return html.htmlToPlainText()
        }
        return content
    }

    var formattedCreatedAt: String {
        createdAt.relativeFormatted()
    }
}

struct RecentCommentsResponse: Codable {
    let comments: [RecentComment]
}

import Foundation
import UIKit

struct Comment: Identifiable, Codable {
    let id: String
    let postId: String
    let parentCommentId: String?
    let actorId: String
    let content: String
    let contentHtml: String?
    let actorName: String
    let actorHandle: String
    let actorLoginName: String?
    let isLocal: Bool
    let createdAt: Date
    let updatedAt: Date
    let children: [Comment]

    var displayText: String {
        if let html = contentHtml {
            return html.htmlToPlainText()
        }
        return content
    }
}

struct CommentsListResponse: Codable {
    let comments: [Comment]
    let pagination: Pagination
}

struct CreateCommentRequest: Codable {
    let content: String
    let parentCommentId: String?

    enum CodingKeys: String, CodingKey {
        case content
        case parentCommentId = "parent_comment_id"
    }
}

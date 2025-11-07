import Foundation

struct ChildPostImage: Codable {
    let url: String
    let width: Int
    let height: Int
}

struct ChildPostAuthor: Codable {
    let id: String
    let loginName: String
    let displayName: String
    let actorHandle: String
}

struct ChildPost: Identifiable, Codable {
    let id: String
    let title: String?
    let content: String?
    let author: ChildPostAuthor
    let image: ChildPostImage
    let publishedAt: Date?
    let commentsCount: Int
    let children: [ChildPost]
}

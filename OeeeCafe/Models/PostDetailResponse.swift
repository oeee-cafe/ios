import Foundation

struct ReactionCount: Codable {
    let emoji: String
    let count: Int
    let reactedByUser: Bool
}

struct Reactor: Identifiable, Codable {
    let iri: String
    let postId: String
    let actorId: String
    let emoji: String
    let createdAt: String
    let actorName: String
    let actorHandle: String

    var id: String { iri }
}

struct ReactorsResponse: Codable {
    let reactions: [Reactor]
}

struct ImageInfo: Codable {
    let filename: String
    let width: Int
    let height: Int
    let tool: String
    let paintDuration: String

    var url: String {
        let prefix = String(filename.prefix(2))
        return "https://r2.oeee.cafe/image/\(prefix)/\(filename)"
    }
}

struct AuthorInfo: Codable {
    let id: String
    let loginName: String
    let displayName: String
}

struct PostCommunityInfo: Codable {
    let id: String
    let name: String
    let slug: String
    let backgroundColor: String?
    let foregroundColor: String?
}

struct PostDetail: Identifiable, Codable {
    let id: String
    let title: String?
    let content: String?
    let author: AuthorInfo
    let viewerCount: Int
    let image: ImageInfo
    let isSensitive: Bool
    let allowRelay: Bool
    let publishedAtUtc: String?
    let community: PostCommunityInfo?
    let hashtags: [String]

    var publishedAt: Date? {
        guard let utcString = publishedAtUtc else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: utcString)
    }
}

struct PostDetailResponse: Codable {
    let post: PostDetail
    let parentPost: ChildPost?
    let childPosts: [ChildPost]
    let reactions: [ReactionCount]
}

struct DeletePostResponse: Codable {
    let success: Bool
}

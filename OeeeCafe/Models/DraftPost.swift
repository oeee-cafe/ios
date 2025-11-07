import Foundation

struct DraftPost: Identifiable, Codable {
    let id: String
    let title: String?
    let imageUrl: String
    let createdAt: String
    let communityId: String
    let width: Int
    let height: Int

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case imageUrl = "image_url"
        case createdAt = "created_at"
        case communityId = "community_id"
        case width
        case height
    }
}

struct DraftPostsResponse: Codable {
    let drafts: [DraftPost]
}

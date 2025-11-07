import Foundation

struct CommunityPost: Identifiable, Codable {
    let id: String
    let imageUrl: String
    let imageWidth: Int
    let imageHeight: Int
    let isSensitive: Bool
}

struct ActiveCommunity: Identifiable, Codable {
    let id: String
    let name: String
    let slug: String
    let description: String?
    let visibility: String
    let ownerLoginName: String
    let postsCount: Int?
    let membersCount: Int?
    let recentPosts: [CommunityPost]
}

struct ActiveCommunitiesResponse: Codable {
    let communities: [ActiveCommunity]
}

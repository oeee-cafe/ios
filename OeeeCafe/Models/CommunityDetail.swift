import Foundation

struct CommunityInfo: Codable {
    let id: String
    let name: String
    let slug: String
    let description: String?
    let visibility: String
    let ownerId: String
    let backgroundColor: String?
    let foregroundColor: String?
    // Note: CodingKeys removed - relying on APIClient's .convertFromSnakeCase strategy
}

struct CommunityStats: Codable {
    let totalPosts: Int
    let totalContributors: Int
    let totalComments: Int
}

struct CommunityDetailPost: Identifiable, Codable {
    let id: String
    let imageUrl: String
    let imageWidth: Int
    let imageHeight: Int
}

struct CommunityDetail: Codable {
    let community: CommunityInfo
    let stats: CommunityStats
    let posts: [CommunityDetailPost]
    let pagination: Pagination
    let comments: [RecentComment]
}

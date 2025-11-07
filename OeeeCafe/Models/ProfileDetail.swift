import Foundation

struct ProfileUser: Codable {
    let id: String
    let loginName: String
    let displayName: String
    let isFollowing: Bool
}

struct ProfileBanner: Codable {
    let id: String
    let imageFilename: String
    let imageUrl: String
}

struct ProfilePost: Identifiable, Codable {
    let id: String
    let imageUrl: String
    let imageWidth: Int
    let imageHeight: Int
}

struct ProfileFollowing: Identifiable, Codable {
    let id: String
    let loginName: String
    let displayName: String
    let bannerImageUrl: String?
    let bannerImageWidth: Int?
    let bannerImageHeight: Int?
}

struct ProfileLink: Identifiable, Codable {
    let id: String
    let url: String
    let description: String?
}

struct ProfileDetail: Codable {
    let user: ProfileUser
    let banner: ProfileBanner?
    let posts: [ProfilePost]
    let pagination: Pagination
    let followings: [ProfileFollowing]
    let totalFollowings: Int
    let links: [ProfileLink]
}

/// Response for profile followings list endpoint with pagination
struct ProfileFollowingsListResponse: Codable {
    let followings: [ProfileFollowing]
    let pagination: Pagination
}

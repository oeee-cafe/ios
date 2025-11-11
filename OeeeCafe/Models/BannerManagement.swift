import Foundation

struct BannerListItem: Identifiable, Codable {
    let id: String
    let imageUrl: String
    let createdAt: String
    let isActive: Bool
}

struct BannerListResponse: Codable {
    let banners: [BannerListItem]
}

import Foundation

struct MyCommunitiesResponse: Codable {
    let communities: [ActiveCommunity]
}

struct PaginationMeta: Codable {
    let offset: Int64
    let limit: Int64
    let total: Int64?
    let hasMore: Bool
}

struct PublicCommunitiesResponse: Codable {
    let communities: [ActiveCommunity]
    let pagination: PaginationMeta
}

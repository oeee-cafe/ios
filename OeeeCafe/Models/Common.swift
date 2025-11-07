import Foundation

/// Pagination metadata for API responses
struct Pagination: Codable {
    let offset: Int
    let limit: Int
    let total: Int?
    let hasMore: Bool
}

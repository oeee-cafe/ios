import Foundation

struct EditPostRequest: Codable {
    let title: String
    let content: String
    let hashtags: String?
    let isSensitive: Bool
    let allowRelay: Bool

    enum CodingKeys: String, CodingKey {
        case title
        case content
        case hashtags
        case isSensitive = "is_sensitive"
        case allowRelay = "allow_relay"
    }
}

struct EditPostResponse: Codable {
    let success: Bool
}

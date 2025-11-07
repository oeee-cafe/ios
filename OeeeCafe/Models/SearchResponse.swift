import Foundation

struct SearchResponse: Codable {
    let users: [SearchUser]
    let posts: [SearchPost]
}

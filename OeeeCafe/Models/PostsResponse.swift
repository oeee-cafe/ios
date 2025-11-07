import Foundation

struct PostsResponse: Codable {
    let posts: [Post]
    let pagination: Pagination
}

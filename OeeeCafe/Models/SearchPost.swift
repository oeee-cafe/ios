import Foundation

struct SearchPost: Identifiable, Codable {
    let id: String
    let imageUrl: String
    let imageWidth: Int
    let imageHeight: Int
    let isSensitive: Bool
}

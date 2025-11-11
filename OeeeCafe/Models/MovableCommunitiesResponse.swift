import Foundation

/// Response from the movable communities API endpoint
struct MovableCommunitiesResponse: Codable {
    let communities: [MovableCommunity]
}

/// A community that a post can be moved to
struct MovableCommunity: Identifiable, Codable {
    let id: String?  // nil for "Personal Post" option
    let name: String
    let slug: String?
    let visibility: String?
    let backgroundColor: String?
    let foregroundColor: String?
    let ownerLoginName: String?
    let ownerDisplayName: String?
    let hasParticipated: Bool?  // nil for "Personal Post" option, true/false for communities

    /// Computed property for SwiftUI List
    var listId: String {
        id ?? "personal"
    }

    /// Check if this is a personal post option
    var isPersonalPost: Bool {
        id == nil
    }

    /// Check if this is a two-tone community
    var isTwoTone: Bool {
        backgroundColor != nil && foregroundColor != nil
    }
}

/// Request body for moving a post to a community
struct MoveCommunityRequest: Codable {
    let communityId: String?  // nil to move to personal posts
}

import Foundation

// MARK: - Community Member Models

struct CommunityMembersListResponse: Codable {
    let members: [CommunityMember]
}

struct CommunityMember: Codable, Identifiable {
    let id: String
    let userId: String
    let username: String
    let displayName: String
    let avatarUrl: String?
    let role: String
    let joinedAt: Date
    let invitedByUsername: String?
    // Note: CodingKeys removed - relying on APIClient's .convertFromSnakeCase strategy
}

// MARK: - Invitation Models

struct UserInvitationsListResponse: Codable {
    let invitations: [UserInvitation]
}

struct UserInvitation: Codable, Identifiable {
    let id: String
    let community: InvitationCommunityInfo
    let inviter: InvitationUserInfo
    let createdAt: Date
    // Note: CodingKeys removed - relying on APIClient's .convertFromSnakeCase strategy
}

struct InvitationCommunityInfo: Codable {
    let id: String
    let name: String
    let slug: String
    let description: String
    let visibility: String
}

struct InvitationUserInfo: Codable {
    let id: String
    let username: String
    let displayName: String
    let avatarUrl: String?
    // Note: CodingKeys removed - relying on APIClient's .convertFromSnakeCase strategy
}

struct CommunityInvitationsListResponse: Codable {
    let invitations: [CommunityInvitation]
}

struct CommunityInvitation: Codable, Identifiable {
    let id: String
    let communityId: String
    let invitee: InvitationUserInfo
    let inviter: InvitationUserInfo
    let createdAt: Date
    // Note: CodingKeys removed - relying on APIClient's .convertFromSnakeCase strategy
}

// MARK: - Community CRUD Models

struct CreateCommunityRequest: Codable {
    let name: String
    let slug: String
    let description: String
    let visibility: String
}

struct CreateCommunityResponse: Codable {
    let community: CommunityInfo
}

struct UpdateCommunityRequest: Codable {
    let name: String
    let description: String
    let visibility: String
}

struct InviteUserRequest: Codable {
    let loginName: String
    // Note: CodingKeys removed - relying on APIClient's .convertToSnakeCase strategy
}

struct InviteUserResponse: Codable {
    // Empty response, API returns 204 No Content on success
}

import Foundation
import os.log

class CommunityService {
    static let shared = CommunityService()
    private let apiClient = APIClient.shared

    private init() {}

    func getMyCommunitiesList() async throws -> MyCommunitiesResponse {
        let communities: MyCommunitiesResponse = try await apiClient.fetch(path: "/api/v1/communities")
        Logger.info("Fetched \(communities.communities.count) my communities", category: Logger.network)
        return communities
    }

    func getPublicCommunities(offset: Int = 0, limit: Int = 20) async throws -> PublicCommunitiesResponse {
        let queryItems = [
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        let communities: PublicCommunitiesResponse = try await apiClient.fetch(
            path: "/api/v1/communities/public",
            queryItems: queryItems
        )
        Logger.info("Fetched \(communities.communities.count) public communities (offset: \(offset), hasMore: \(communities.pagination.hasMore))", category: Logger.network)
        return communities
    }

    func searchPublicCommunities(query: String, offset: Int = 0, limit: Int = 20) async throws -> PublicCommunitiesResponse {
        let queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        let communities: PublicCommunitiesResponse = try await apiClient.fetch(
            path: "/api/v1/communities/search",
            queryItems: queryItems
        )
        Logger.info("Searched \(communities.communities.count) communities for '\(query)' (offset: \(offset), hasMore: \(communities.pagination.hasMore))", category: Logger.network)
        return communities
    }

    // MARK: - Member Management

    func getCommunityMembers(slug: String) async throws -> CommunityMembersListResponse {
        let members: CommunityMembersListResponse = try await apiClient.fetch(
            path: "/api/v1/communities/\(slug)/members"
        )
        Logger.info("Fetched \(members.members.count) members for community @\(slug)", category: Logger.network)
        return members
    }

    func inviteUser(slug: String, loginName: String) async throws {
        let request = InviteUserRequest(loginName: loginName)
        try await apiClient.post(path: "/api/v1/communities/\(slug)/members", body: request)
        Logger.info("Invited user '\(loginName)' to community @\(slug)", category: Logger.network)
    }

    func removeMember(slug: String, userId: String) async throws {
        try await apiClient.delete(path: "/api/v1/communities/\(slug)/members/\(userId)")
        Logger.info("Removed member \(userId) from community @\(slug)", category: Logger.network)
    }

    func getCommunityInvitations(slug: String) async throws -> CommunityInvitationsListResponse {
        let invitations: CommunityInvitationsListResponse = try await apiClient.fetch(
            path: "/api/v1/communities/\(slug)/invitations"
        )
        Logger.info("Fetched \(invitations.invitations.count) pending invitations for community @\(slug)", category: Logger.network)
        return invitations
    }

    func retractInvitation(slug: String, invitationId: String) async throws {
        try await apiClient.delete(path: "/api/v1/communities/\(slug)/invitations/\(invitationId)")
        Logger.info("Retracted invitation \(invitationId) for community @\(slug)", category: Logger.network)
    }

    // MARK: - User Invitations

    func getUserInvitations() async throws -> UserInvitationsListResponse {
        let invitations: UserInvitationsListResponse = try await apiClient.fetch(
            path: "/api/v1/invitations"
        )
        Logger.info("Fetched \(invitations.invitations.count) pending invitations for user", category: Logger.network)
        return invitations
    }

    func acceptInvitation(id: String) async throws {
        try await apiClient.post(path: "/invitations/\(id)/accept")
        Logger.info("Accepted invitation \(id)", category: Logger.network)
    }

    func rejectInvitation(id: String) async throws {
        try await apiClient.post(path: "/invitations/\(id)/reject")
        Logger.info("Rejected invitation \(id)", category: Logger.network)
    }

    // MARK: - Community CRUD

    func createCommunity(request: CreateCommunityRequest) async throws -> CreateCommunityResponse {
        let response: CreateCommunityResponse = try await apiClient.post(
            path: "/api/v1/communities",
            body: request
        )
        Logger.info("Created community @\(response.community.slug)", category: Logger.network)
        return response
    }

    func updateCommunity(slug: String, request: UpdateCommunityRequest) async throws {
        try await apiClient.put(path: "/api/v1/communities/\(slug)", body: request)
        Logger.info("Updated community @\(slug)", category: Logger.network)
    }

    func deleteCommunity(slug: String) async throws {
        try await apiClient.delete(path: "/api/v1/communities/\(slug)")
        Logger.info("Deleted community @\(slug)", category: Logger.network)
    }
}

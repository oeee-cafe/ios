import Foundation
import SwiftUI
import Combine

/// Coordinator for handling deep link navigation from push notifications and other sources
class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()

    @Published var selectedTab: String = "home"
    @Published var navigationPath = NavigationPath()
    @Published var pendingNavigation: PendingNavigation?

    private init() {}

    enum PendingNavigation: Equatable {
        case post(id: String)
        case profile(loginName: String)
        case community(slug: String)
        case communityMembers(slug: String)
        case invitations
        case notifications
    }

    /// Navigate to a post detail screen
    func navigateToPost(id: String) {
        Logger.debug("NavigationCoordinator: Navigating to post \(id)", category: Logger.app)
        pendingNavigation = .post(id: id)
        selectedTab = "home"
    }

    /// Navigate to a user profile screen
    func navigateToProfile(loginName: String) {
        Logger.debug("NavigationCoordinator: Navigating to profile @\(loginName)", category: Logger.app)
        pendingNavigation = .profile(loginName: loginName)
        selectedTab = "home"
    }

    /// Navigate to a community detail screen
    func navigateToCommunity(slug: String) {
        Logger.debug("NavigationCoordinator: Navigating to community @\(slug)", category: Logger.app)
        pendingNavigation = .community(slug: slug)
        selectedTab = "communities"
    }

    /// Navigate to community members screen
    func navigateToCommunityMembers(slug: String) {
        Logger.debug("NavigationCoordinator: Navigating to community @\(slug) members", category: Logger.app)
        pendingNavigation = .communityMembers(slug: slug)
        selectedTab = "communities"
    }

    /// Navigate to community invitations screen
    func navigateToInvitations() {
        Logger.debug("NavigationCoordinator: Navigating to invitations", category: Logger.app)
        pendingNavigation = .invitations
        selectedTab = "communities"
    }

    /// Navigate to notifications tab
    func navigateToNotifications() {
        Logger.debug("NavigationCoordinator: Navigating to notifications tab", category: Logger.app)
        pendingNavigation = .notifications
        selectedTab = "notifications"
    }

    /// Handle push notification payload and navigate to the appropriate screen
    func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        Logger.debug("NavigationCoordinator: Handling notification tap with data: \(userInfo)", category: Logger.app)

        guard let notificationType = userInfo["notification_type"] as? String else {
            Logger.warning("NavigationCoordinator: No notification_type found in payload", category: Logger.app)
            return
        }

        Logger.info("NavigationCoordinator: Processing notification type: \(notificationType)", category: Logger.app)

        switch notificationType {
        case "Comment", "Mention", "CommentReply", "PostReply", "CommunityPost", "Reaction":
            // Navigate to post detail
            if let postId = userInfo["post_id"] as? String {
                navigateToPost(id: postId)
            } else {
                Logger.warning("NavigationCoordinator: Missing post_id for \(notificationType)", category: Logger.app)
            }

        case "Follow":
            // Navigate to actor's profile
            if let actorLoginName = userInfo["actor_login_name"] as? String {
                navigateToProfile(loginName: actorLoginName)
            } else {
                Logger.warning("NavigationCoordinator: Missing actor_login_name for Follow", category: Logger.app)
            }

        case "GuestbookEntry", "GuestbookReply":
            // Navigate to actor's profile (guestbook tab)
            if let actorLoginName = userInfo["actor_login_name"] as? String {
                navigateToProfile(loginName: actorLoginName)
            } else {
                Logger.warning("NavigationCoordinator: Missing actor_login_name for \(notificationType)", category: Logger.app)
            }

        case "community_invite":
            // Navigate to community invitations screen
            navigateToInvitations()

        case "invitation_accepted", "invitation_declined":
            // Navigate to community members screen
            if let communitySlug = userInfo["community_slug"] as? String {
                navigateToCommunityMembers(slug: communitySlug)
            } else {
                Logger.warning("NavigationCoordinator: Missing community_slug for \(notificationType)", category: Logger.app)
            }

        default:
            Logger.warning("NavigationCoordinator: Unknown notification type: \(notificationType)", category: Logger.app)
            // Fallback: Navigate to notifications tab
            navigateToNotifications()
        }
    }

    /// Clear pending navigation after it has been processed
    func clearPendingNavigation() {
        pendingNavigation = nil
    }
}

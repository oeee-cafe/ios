import Foundation
import Combine

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: String?
    @Published var unreadCount = 0
    @Published var invitationCount = 0

    private let notificationService = NotificationService.shared
    private let communityService = CommunityService.shared
    private var currentOffset = 0
    private var hasMore = true
    private let pageSize = 50

    /// Load initial notifications
    func loadInitial() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil
        currentOffset = 0

        do {
            let response = try await notificationService.fetchNotifications(limit: pageSize, offset: 0)
            // Filter out unknown notification types
            notifications = response.notifications.filter { $0.notificationType != .unknown }
            hasMore = response.hasMore
            currentOffset = pageSize

            // Also update unread count and invitation count
            await updateUnreadCount()
            await updateInvitationCount()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    /// Load more notifications (pagination)
    func loadMore() async {
        guard !isLoadingMore && hasMore else { return }

        isLoadingMore = true

        do {
            let response = try await notificationService.fetchNotifications(
                limit: pageSize,
                offset: currentOffset
            )

            // Filter out unknown notification types
            let filteredNotifications = response.notifications.filter { $0.notificationType != .unknown }
            notifications.append(contentsOf: filteredNotifications)
            hasMore = response.hasMore
            currentOffset += pageSize
        } catch {
            self.error = error.localizedDescription
        }

        isLoadingMore = false
    }

    /// Refresh notifications (pull-to-refresh)
    func refresh() async {
        currentOffset = 0
        await loadInitial()
    }

    /// Update unread count
    func updateUnreadCount() async {
        do {
            unreadCount = try await notificationService.getUnreadCount()
        } catch {
            // Silently fail for unread count updates
            Logger.debug("Failed to update unread count: \(error.localizedDescription)", category: Logger.data)
        }
    }

    /// Update invitation count
    func updateInvitationCount() async {
        do {
            let response = try await communityService.getUserInvitations()
            invitationCount = response.invitations.count
        } catch {
            // Silently fail for invitation count updates
            Logger.debug("Failed to update invitation count: \(error.localizedDescription)", category: Logger.data)
        }
    }

    /// Mark a notification as read
    func markAsRead(_ notification: NotificationItem) async {
        guard notification.readAt == nil else { return }

        do {
            if let updatedNotification = try await notificationService.markAsRead(notificationId: notification.id) {
                // Update the notification in the list
                if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                    notifications[index] = updatedNotification
                }

                // Update unread count
                await updateUnreadCount()
            }
        } catch {
            self.error = "Failed to mark as read: \(error.localizedDescription)"
        }
    }

    /// Mark all notifications as read
    func markAllAsRead() async {
        do {
            _ = try await notificationService.markAllAsRead()

            // Refresh to get updated read status
            await refresh()

            // Explicitly update unread count after refresh to ensure badge is updated
            await updateUnreadCount()
        } catch {
            self.error = "Failed to mark all as read: \(error.localizedDescription)"
        }
    }

    /// Delete a notification
    func deleteNotification(_ notification: NotificationItem) async {
        do {
            try await notificationService.deleteNotification(notificationId: notification.id)

            // Remove from local list
            notifications.removeAll { $0.id == notification.id }

            // Update unread count
            await updateUnreadCount()
        } catch {
            self.error = "Failed to delete notification: \(error.localizedDescription)"
        }
    }
}

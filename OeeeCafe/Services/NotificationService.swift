import Foundation

class NotificationService {
    static let shared = NotificationService()

    private let apiClient = APIClient.shared

    private init() {}

    /// Fetch notifications with pagination
    func fetchNotifications(limit: Int = 50, offset: Int = 0) async throws -> NotificationsResponse {
        let queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]

        let response: NotificationsResponse = try await apiClient.fetch(
            path: "/api/v1/notifications",
            queryItems: queryItems
        )

        return response
    }

    /// Get unread notification count
    func getUnreadCount() async throws -> Int {
        let response: UnreadCountResponse = try await apiClient.fetch(
            path: "/api/v1/notifications/unread-count"
        )

        return response.count
    }

    /// Mark a specific notification as read
    func markAsRead(notificationId: String) async throws -> NotificationItem? {
        let response: MarkReadResponse = try await apiClient.post(
            path: "/api/v1/notifications/\(notificationId)/mark-read",
            body: EmptyRequest()
        )

        return response.notification
    }

    /// Mark all notifications as read
    func markAllAsRead() async throws -> Int {
        let response: MarkAllReadResponse = try await apiClient.post(
            path: "/api/v1/notifications/mark-all-read",
            body: EmptyRequest()
        )

        return response.count
    }

    /// Delete a specific notification
    func deleteNotification(notificationId: String) async throws {
        // Server returns 204 No Content on success, so use the no-response-body DELETE method
        try await apiClient.delete(
            path: "/api/v1/notifications/\(notificationId)"
        )
    }
}

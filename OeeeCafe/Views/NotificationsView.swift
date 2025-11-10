import SwiftUI
import UserNotifications

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    @EnvironmentObject var authService: AuthService

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    LoadingStateView(message: "notifications.loading".localized)
                } else if let error = viewModel.error, viewModel.notifications.isEmpty {
                    ErrorStateView(error: error) {
                        Task {
                            await viewModel.loadInitial()
                        }
                    }
                } else if viewModel.notifications.isEmpty {
                    EmptyStateView(
                        icon: "bell.slash",
                        title: "notifications.empty".localized,
                        message: "notifications.empty_message".localized
                    )
                } else {
                    // Notifications list
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.notifications) { notification in
                                NotificationCard(
                                    notification: notification,
                                    onMarkRead: {
                                        Task {
                                            await viewModel.markAsRead(notification)
                                        }
                                    },
                                    onDelete: {
                                        Task {
                                            await viewModel.deleteNotification(notification)
                                        }
                                    }
                                )
                                .onAppear {
                                    // Load more when reaching the last item
                                    if notification.id == viewModel.notifications.last?.id {
                                        Task {
                                            await viewModel.loadMore()
                                        }
                                    }
                                }

                                Divider()
                            }

                            // Loading more indicator
                            if viewModel.isLoadingMore {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .padding()
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("notifications.title".localized)
            .refreshable {
                await Task { @MainActor in
                    await viewModel.refresh()
                }.value
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Community Invitations button with badge
                    NavigationLink(destination: CommunityInvitationsView()) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "envelope")
                                .font(.title3)

                            // Red dot badge when there are pending invitations
                            if viewModel.invitationCount > 0 {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }

                    // Mark all read button
                    if !viewModel.notifications.isEmpty {
                        Button("notifications.mark_all_read".localized) {
                            Task {
                                await viewModel.markAllAsRead()
                            }
                        }
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .task {
            // Clear app badge when viewing notifications
            do {
                try await UNUserNotificationCenter.current().setBadgeCount(0)
                Logger.debug("Cleared app badge when viewing notifications", category: Logger.app)
            } catch {
                Logger.error("Failed to clear app badge", error: error, category: Logger.app)
            }

            await viewModel.loadInitial()

            // Auto-mark all notifications as read when viewing the notifications screen
            if viewModel.unreadCount > 0 {
                Logger.debug("Auto-marking \(viewModel.unreadCount) unread notifications as read", category: Logger.app)
                await viewModel.markAllAsRead()
            }

            // Load invitation count for badge
            await viewModel.updateInvitationCount()
        }
        .onAppear {
            // Refresh invitation count when returning to this view
            Task {
                await viewModel.updateInvitationCount()
            }
        }
    }
}

#Preview {
    NotificationsView()
        .environmentObject(AuthService.shared)
}

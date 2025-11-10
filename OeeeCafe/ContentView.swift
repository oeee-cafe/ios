//
//  ContentView.swift
//  OeeeCafe
//
//  Created by Jihyeok Seo on 10/29/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var notificationsViewModel = NotificationsViewModel()
    @StateObject private var draftsViewModel = DraftsViewModel()
    @State private var tabSelection: String = "home"

    var body: some View {
        Group {
            if authService.isCheckingAuth {
                // Show loading indicator while checking auth status
                VStack(spacing: 16) {
                    ProgressView()
                    Text("common.loading".localized)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TabView(selection: $tabSelection) {
                    Tab("tab.home".localized, systemImage: "house.fill", value: "home") {
                        HomeView()
                    }

                    Tab("tab.communities".localized, systemImage: "person.3.fill", value: "communities") {
                        CommunitiesView()
                    }

                    if authService.isAuthenticated {
                        // Show drafts tab when logged in
                        // Keep Tab structure constant - badge is always present but may be empty
                        let draftBadgeText = draftsViewModel.drafts.count > 0 ? "\(draftsViewModel.drafts.count)" : ""
                        Tab("tab.drafts".localized, systemImage: "doc.text", value: "drafts") {
                            DraftsView()
                        }
                        .badge(draftBadgeText)

                        // Show notifications tab when logged in
                        // Keep Tab structure constant - badge is always present but may be empty
                        let totalNotificationBadge = notificationsViewModel.unreadCount + notificationsViewModel.invitationCount
                        let notificationBadgeText = totalNotificationBadge > 0 ? "\(totalNotificationBadge)" : ""
                        Tab("tab.notifications".localized, systemImage: "bell", value: "notifications") {
                            NotificationsView()
                        }
                        .badge(notificationBadgeText)
                    } else {
                        // Show login tab when logged out
                        Tab("tab.login".localized, systemImage: "person.circle", value: "login") {
                            NavigationStack {
                                LoginView()
                            }
                        }
                    }

                    Tab("tab.search".localized, systemImage: "magnifyingglass", value: "search", role: .search) {
                        SearchView()
                    }
                }
            }
        }
        .task {
            // Configure Kingfisher (moved from app init to prevent blocking UI)
            Task { @MainActor in
                KingfisherConfig.configure()
            }

            // Restore auth session (this was moved from AuthService init to allow UI to appear first)
            authService.restoreSession()

            // Fetch counts at app startup if authenticated
            if authService.isAuthenticated {
                await notificationsViewModel.updateUnreadCount()
                await notificationsViewModel.updateInvitationCount()
                await draftsViewModel.loadDrafts()
            }
        }
        .onAppear {
            // Refresh counts when view appears (e.g., returning from background)
            if authService.isAuthenticated {
                Task {
                    await notificationsViewModel.updateUnreadCount()
                    await notificationsViewModel.updateInvitationCount()
                    await draftsViewModel.loadDrafts()
                }
            }
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            // Refresh counts when authentication state changes
            if isAuthenticated {
                Task {
                    await notificationsViewModel.updateUnreadCount()
                    await notificationsViewModel.updateInvitationCount()
                    await draftsViewModel.loadDrafts()
                }
            } else {
                // Clear counts when logged out
                notificationsViewModel.unreadCount = 0
                notificationsViewModel.invitationCount = 0
                draftsViewModel.drafts = []
            }
        }
        .environmentObject(notificationsViewModel)
        .environmentObject(draftsViewModel)
    }
}

#Preview {
    ContentView()
}

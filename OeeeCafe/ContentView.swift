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
                TabView {
                    Tab("tab.home".localized, systemImage: "house.fill") {
                        HomeView()
                    }

                    Tab(role: .search) {
                        SearchView()
                    }

                    Tab("tab.communities".localized, systemImage: "person.3.fill") {
                        CommunitiesView()
                    }

                    if authService.isAuthenticated {
                        // Show drafts tab when logged in
                        if draftsViewModel.drafts.count > 0 {
                            Tab("tab.drafts".localized, systemImage: "doc.text") {
                                DraftsView()
                            }
                            .badge(draftsViewModel.drafts.count)
                        } else {
                            Tab("tab.drafts".localized, systemImage: "doc.text") {
                                DraftsView()
                            }
                        }

                        // Show notifications tab when logged in
                        let totalNotificationBadge = notificationsViewModel.unreadCount + notificationsViewModel.invitationCount
                        if totalNotificationBadge > 0 {
                            Tab("tab.notifications".localized, systemImage: "bell") {
                                NotificationsView()
                            }
                            .badge(totalNotificationBadge)
                        } else {
                            Tab("tab.notifications".localized, systemImage: "bell") {
                                NotificationsView()
                            }
                        }
                    } else {
                        // Show login tab when logged out
                        Tab("tab.login".localized, systemImage: "person.circle") {
                            NavigationStack {
                                LoginView()
                            }
                        }
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

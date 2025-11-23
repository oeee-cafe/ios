import SwiftUI

struct CommunitiesView: View {
    @StateObject private var viewModel = CommunitiesViewModel()
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @State private var showCreateCommunity = false
    @State private var navigateToCommunitySlug: String?
    @State private var showInvitations = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Search box
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("community.search_placeholder".localized, text: $viewModel.searchQuery)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()
                        if !viewModel.searchQuery.isEmpty {
                            Button(action: {
                                viewModel.searchQuery = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                    if viewModel.isLoading && viewModel.myCommunities.isEmpty && viewModel.publicCommunities.isEmpty {
                        LoadingStateView(message: "common.loading".localized)
                            .padding(.top, 100)
                    } else if let error = viewModel.error, viewModel.myCommunities.isEmpty && viewModel.publicCommunities.isEmpty {
                        ErrorStateView(error: error.localizedDescription) {
                            Task {
                                await viewModel.loadCommunities()
                            }
                        }
                        .padding(.top, 100)
                    } else {
                        LazyVStack(spacing: 12) {
                            // Private Communities Section
                            if authService.isAuthenticated && !viewModel.filteredPrivateCommunities.isEmpty {
                                Text("community.private_communities".localized)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                ForEach(viewModel.filteredPrivateCommunities) { community in
                                    CommunityCard(community: community)
                                        .padding(.horizontal)
                                }
                            }

                            // Unlisted Communities Section
                            if authService.isAuthenticated && !viewModel.filteredUnlistedCommunities.isEmpty {
                                Text("community.unlisted_communities".localized)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                    .padding(.top, authService.isAuthenticated && !viewModel.filteredPrivateCommunities.isEmpty ? 24 : 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                ForEach(viewModel.filteredUnlistedCommunities) { community in
                                    CommunityCard(community: community)
                                        .padding(.horizontal)
                                }
                            }

                            // My Public Communities Section
                            if authService.isAuthenticated && !viewModel.filteredPublicMyCommunities.isEmpty {
                                Text("community.my_public_communities".localized)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                    .padding(.top, authService.isAuthenticated && (!viewModel.filteredPrivateCommunities.isEmpty || !viewModel.filteredUnlistedCommunities.isEmpty) ? 24 : 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                ForEach(viewModel.filteredPublicMyCommunities) { community in
                                    CommunityCard(community: community)
                                        .padding(.horizontal)
                                }
                            }

                            // Other Public Communities Section
                            let allPublicCommunities = viewModel.searchQuery.isEmpty ? viewModel.filteredPublicCommunities : viewModel.searchResults
                            // Filter out communities that are already in My Communities to avoid duplicate IDs
                            let myCommunityIds = Set(viewModel.filteredMyCommunities.map { $0.id })
                            let publicCommunities = allPublicCommunities.filter { !myCommunityIds.contains($0.id) }

                            if !publicCommunities.isEmpty {
                                let hasAnySectionAbove = authService.isAuthenticated && (!viewModel.filteredPrivateCommunities.isEmpty || !viewModel.filteredUnlistedCommunities.isEmpty || !viewModel.filteredPublicMyCommunities.isEmpty)
                                Text(viewModel.searchQuery.isEmpty ? "community.other_public_communities".localized : "community.search_results".localized)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                    .padding(.top, hasAnySectionAbove ? 24 : 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                ForEach(Array(publicCommunities.enumerated()), id: \.element.id) { index, community in
                                    CommunityCard(community: community)
                                        .padding(.horizontal)
                                        .onAppear {
                                            // Load more when showing one of the last 3 items (only in browse mode)
                                            if viewModel.searchQuery.isEmpty && index >= publicCommunities.count - 3 {
                                                Task {
                                                    await viewModel.loadMorePublicCommunities()
                                                }
                                            }
                                        }
                                }

                                // Loading more or searching indicator
                                if viewModel.isLoadingMore || viewModel.isSearching {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                        Spacer()
                                    }
                                    .padding()
                                }
                            }

                            // Empty state
                            let showEmptyState = viewModel.searchQuery.isEmpty ?
                                (viewModel.filteredMyCommunities.isEmpty && viewModel.filteredPublicCommunities.isEmpty && !viewModel.isLoading) :
                                (viewModel.filteredMyCommunities.isEmpty && viewModel.searchResults.isEmpty && !viewModel.isSearching)

                            if showEmptyState {
                                VStack(spacing: 16) {
                                    Image(systemName: "person.3")
                                        .font(.system(size: 48))
                                        .foregroundColor(.secondary)
                                    if viewModel.searchQuery.isEmpty {
                                        Text("community.no_communities".localized)
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("community.no_search_results".localized)
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 100)
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("tab.communities".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if authService.isAuthenticated {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showCreateCommunity = true }) {
                            Image(systemName: "plus")
                                .font(.title3)
                        }
                    }
                }
            }
            .refreshable {
                await Task { @MainActor in
                    await viewModel.loadCommunities()
                }.value
            }
            .sheet(isPresented: $showCreateCommunity) {
                CreateCommunityView { slug in
                    // Delay navigation slightly to allow sheet to dismiss
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        navigateToCommunitySlug = slug
                    }
                }
            }
            .navigationDestination(item: $navigateToCommunitySlug) { slug in
                CommunityDetailView(slug: slug)
            }
            .sheet(isPresented: $showInvitations) {
                NavigationStack {
                    CommunityInvitationsView()
                }
            }
            .onChange(of: navigationCoordinator.pendingNavigation) { _, newValue in
                // Handle deep link navigation from push notifications
                guard let pending = newValue else { return }

                switch pending {
                case .community(let slug), .communityMembers(let slug):
                    // Navigate to community detail (user can access members from there)
                    navigateToCommunitySlug = slug
                case .invitations:
                    showInvitations = true
                default:
                    // Other navigation types are handled by other tabs
                    break
                }

                // Clear the pending navigation after handling
                navigationCoordinator.clearPendingNavigation()
            }
        }
        .task {
            await viewModel.loadCommunities()
        }
        .onAppear {
            // Refresh when returning to this view
            Task {
                await viewModel.loadCommunities()
            }
        }
    }
}

#Preview {
    CommunitiesView()
        .environmentObject(AuthService.shared)
}

import SwiftUI

struct CommunitiesView: View {
    @StateObject private var viewModel = CommunitiesViewModel()
    @EnvironmentObject var authService: AuthService
    @State private var showCreateCommunity = false
    @State private var navigateToCommunitySlug: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
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
                        VStack(spacing: 24) {
                            // My Communities Section
                            if authService.isAuthenticated && !viewModel.filteredMyCommunities.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("community.my_communities".localized)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal)

                                    ForEach(viewModel.filteredMyCommunities) { community in
                                        CommunityCard(community: community)
                                            .padding(.horizontal)
                                    }
                                }
                                .padding(.top, 8)
                            }

                            // Public Communities Section
                            let publicCommunities = viewModel.searchQuery.isEmpty ? viewModel.filteredPublicCommunities : viewModel.searchResults

                            if !publicCommunities.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(viewModel.searchQuery.isEmpty ? "community.public_communities".localized : "community.search_results".localized)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal)

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
                                .padding(.top, authService.isAuthenticated && !viewModel.filteredMyCommunities.isEmpty ? 24 : 8)
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

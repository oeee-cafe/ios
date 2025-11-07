import SwiftUI
import Kingfisher

struct FollowingListView: View {
    let loginName: String
    @StateObject private var viewModel: FollowingListViewModel
    @EnvironmentObject var authService: AuthService

    init(loginName: String) {
        self.loginName = loginName
        _viewModel = StateObject(wrappedValue: FollowingListViewModel(loginName: loginName))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("common.loading".localized)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    Text("common.error".localized(error))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("common.retry".localized) {
                        Task {
                            await viewModel.loadFollowings()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else if viewModel.followings.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)

                    Text("profile.following".localized(0))
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(viewModel.followings) { following in
                    NavigationLink(destination: ProfileView(loginName: following.loginName)
                        .environmentObject(authService)) {
                        HStack(spacing: 12) {
                            // Banner or placeholder
                            if let bannerUrl = following.bannerImageUrl, let url = URL(string: bannerUrl) {
                                KFImage(url)
                                    .placeholder {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 60, height: 60)
                                            .cornerRadius(8)
                                            .overlay {
                                                ProgressView()
                                            }
                                    }
                                    .onFailure { error in
                                        print("Failed to load banner for \(following.loginName): \(error)")
                                    }
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipped()
                                    .cornerRadius(8)
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                                    .overlay {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.gray)
                                    }
                            }

                            // User info
                            VStack(alignment: .leading, spacing: 4) {
                                Text(following.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)

                                Text("@\(following.loginName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .onAppear {
                        // Load more when the last item appears
                        if following.id == viewModel.followings.last?.id {
                            Task {
                                await viewModel.loadMoreFollowings()
                            }
                        }
                    }
                }

                    // Loading indicator at bottom when loading more
                    if viewModel.isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding()
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await Task { @MainActor in
                        await viewModel.refresh()
                    }.value
                }
            }
        }
        .navigationTitle("profile.see_all_following".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadFollowings()
        }
    }
}

#Preview {
    NavigationView {
        FollowingListView(loginName: "alice")
            .environmentObject(AuthService.shared)
    }
}

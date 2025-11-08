import SwiftUI
import Kingfisher

struct ProfileFollowingsSection: View {
    let followings: [ProfileFollowing]
    let totalFollowings: Int
    let loginName: String
    @EnvironmentObject var authService: AuthService

    var body: some View {
        if !followings.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("profile.following".localized(totalFollowings))
                    .font(.headline)
                    .padding(.horizontal)

                // Grid of users with banners
                let usersWithBanners = followings.filter { $0.bannerImageUrl != nil }
                if !usersWithBanners.isEmpty {
                    LazyVGrid(columns: Constants.twoColumnGrid, spacing: 8) {
                        ForEach(usersWithBanners) { following in
                            if let bannerURL = following.bannerImageUrl.flatMap({ URL(string: $0) }) {
                                NavigationLink(destination: ProfileView(loginName: following.loginName)
                                    .environmentObject(authService)) {
                                    GeometryReader { geometry in
                                        KFImage(bannerURL)
                                            .placeholder {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.2))
                                                    .overlay {
                                                        ProgressView()
                                                    }
                                            }
                                            .onFailure { error in
                                                // Error handling - Kingfisher will display placeholder
                                            }
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: geometry.size.width, height: geometry.size.height)
                                            .clipped()
                                    }
                                    .aspectRatio(
                                        {
                                            if let width = following.bannerImageWidth,
                                               let height = following.bannerImageHeight {
                                                return CGFloat(width) / CGFloat(height)
                                            }
                                            return 16.0 / 9.0
                                        }(),
                                        contentMode: .fit
                                    )
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }

                // See All navigation link
                NavigationLink(destination: FollowingListView(loginName: loginName)
                    .environmentObject(authService)) {
                    HStack {
                        Text("profile.see_all_following".localized)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
            }
        }
    }
}

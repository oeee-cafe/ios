import SwiftUI
import Kingfisher

struct BannerManagementView: View {
    @Environment(\.dismiss) var dismiss
    @State private var banners: [BannerListItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirmation = false
    @State private var bannerToDelete: BannerListItem?
    @State private var showBannerDraw = false

    private let bannerService = BannerService.shared

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView()
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            Task {
                                await loadBanners()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if banners.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No banners yet")
                            .font(.headline)
                        Text("Create your first banner to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(banners) { banner in
                                BannerCard(
                                    banner: banner,
                                    onActivate: {
                                        Task {
                                            await activateBanner(banner)
                                        }
                                    },
                                    onDelete: {
                                        bannerToDelete = banner
                                        showDeleteConfirmation = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Banner Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Create New") {
                        showBannerDraw = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showBannerDraw) {
                BannerDrawWebView(onBannerComplete: { bannerId, imageUrl in
                    // Reload banners after drawing completes
                    Task {
                        await loadBanners()
                    }
                })
            }
            .alert("Delete Banner", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let banner = bannerToDelete {
                        Task {
                            await deleteBanner(banner)
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete this banner? This action cannot be undone.")
            }
        }
        .task {
            await loadBanners()
        }
    }

    private func loadBanners() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await bannerService.fetchBanners()
            banners = response.banners
        } catch {
            errorMessage = "Failed to load banners: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func activateBanner(_ banner: BannerListItem) async {
        do {
            try await bannerService.activateBanner(bannerId: banner.id)
            await loadBanners() // Reload to update active status
        } catch {
            errorMessage = "Failed to activate banner: \(error.localizedDescription)"
        }
    }

    private func deleteBanner(_ banner: BannerListItem) async {
        do {
            try await bannerService.deleteBanner(bannerId: banner.id)
            await loadBanners() // Reload to remove deleted banner
        } catch {
            errorMessage = "Failed to delete banner: \(error.localizedDescription)"
        }
    }
}

struct BannerCard: View {
    let banner: BannerListItem
    let onActivate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            KFImage(URL(string: banner.imageUrl))
                .placeholder {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            ProgressView()
                        }
                }
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                if banner.isActive {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Active")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                } else {
                    Button(action: onActivate) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Set as Active")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button(action: onDelete) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.red)
                }

                Text(formatDate(banner.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(banner.isActive ? Color.green.opacity(0.1) : Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(banner.isActive ? Color.green : Color.gray.opacity(0.2), lineWidth: banner.isActive ? 2 : 1)
        )
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }

        // Fallback to original string if parsing fails
        return dateString
    }
}

#Preview {
    BannerManagementView()
}

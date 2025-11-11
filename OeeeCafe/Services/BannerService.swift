import Foundation

class BannerService {
    static let shared = BannerService()

    private let apiClient = APIClient.shared

    private init() {}

    func fetchBanners() async throws -> BannerListResponse {
        return try await apiClient.fetch(
            path: "/api/v1/banners",
            queryItems: nil
        )
    }

    func activateBanner(bannerId: String) async throws {
        let _: EmptyResponse = try await apiClient.post(
            path: "/api/v1/banners/\(bannerId)/activate",
            body: EmptyRequest()
        )
    }

    func deleteBanner(bannerId: String) async throws {
        try await apiClient.delete(path: "/api/v1/banners/\(bannerId)")
    }
}

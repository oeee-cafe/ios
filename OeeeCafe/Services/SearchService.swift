import Foundation

class SearchService {
    static let shared = SearchService()

    private let apiClient = APIClient.shared

    private init() {}

    func search(query: String, limit: Int? = nil) async throws -> SearchResponse {
        var queryItems = [URLQueryItem(name: "q", value: query)]

        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }

        return try await apiClient.fetch(
            path: "/api/v1/search",
            queryItems: queryItems
        )
    }
}

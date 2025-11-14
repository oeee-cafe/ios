import Foundation

enum DraftsServiceError: Error {
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case httpError(Int)
    case networkError(Error)
}

class DraftsService {
    func fetchDraftPosts() async throws -> [DraftPost] {
        guard let url = URL(string: "\(APIConfig.shared.baseURL)/api/v1/posts/drafts") else {
            throw DraftsServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Add session cookies
        if let cookies = HTTPCookieStorage.shared.cookies(for: url) {
            let headers = HTTPCookie.requestHeaderFields(with: cookies)
            for (name, value) in headers {
                request.setValue(value, forHTTPHeaderField: name)
            }
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw DraftsServiceError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw DraftsServiceError.httpError(httpResponse.statusCode)
            }

            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(DraftPostsResponse.self, from: data)
                return result.drafts
            } catch {
                Logger.error("Failed to decode draft posts", error: error, category: Logger.network)
                throw DraftsServiceError.decodingError(error)
            }
        } catch let error as DraftsServiceError {
            throw error
        } catch {
            Logger.error("Network error fetching draft posts", error: error, category: Logger.network)
            throw DraftsServiceError.networkError(error)
        }
    }

    func deleteDraft(postId: String) async throws {
        guard let url = URL(string: "\(APIConfig.shared.baseURL)/api/v1/posts/\(postId)") else {
            throw DraftsServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        // Add session cookies
        if let cookies = HTTPCookieStorage.shared.cookies(for: url) {
            let headers = HTTPCookie.requestHeaderFields(with: cookies)
            for (name, value) in headers {
                request.setValue(value, forHTTPHeaderField: name)
            }
        }

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw DraftsServiceError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw DraftsServiceError.httpError(httpResponse.statusCode)
            }
        } catch let error as DraftsServiceError {
            throw error
        } catch {
            Logger.error("Network error deleting draft post", error: error, category: Logger.network)
            throw DraftsServiceError.networkError(error)
        }
    }
}

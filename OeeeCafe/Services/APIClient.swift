import Foundation
import os.log

// MARK: - Error Response Models

struct APIErrorResponse: Codable {
    let error: APIErrorDetail
}

struct APIErrorDetail: Codable {
    let code: String
    let message: String
}

// MARK: - API Error

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case encodingError(Error)
    case serverError(code: String, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            let nsError = error as NSError
            return "Network error: \(error.localizedDescription) (domain: \(nsError.domain), code: \(nsError.code))"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .serverError(let code, let message):
            // Try to get localized message for error code, fall back to server message
            let localizedKey = "error.\(code.lowercased())"
            let localizedMessage = NSLocalizedString(localizedKey, comment: "")
            // If localization key not found, NSLocalizedString returns the key itself
            if localizedMessage != localizedKey {
                return localizedMessage
            }
            return message
        }
    }
}

class APIClient {
    static let shared = APIClient()

    private var baseURL: String {
        return APIConfig.shared.baseURL
    }
    private let session: URLSession
    private let cookieManager = CookieManager.shared

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60

        // Enable persistent cookie storage
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true

        self.session = URLSession(configuration: configuration)
    }

    // Shared date decoding strategy to handle fractional seconds in ISO 8601
    private static var customDateDecodingStrategy: JSONDecoder.DateDecodingStrategy {
        .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Create formatter inside closure to avoid Sendable issues
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            // Fallback to standard ISO8601 without fractional seconds
            dateFormatter.formatOptions = [.withInternetDateTime]
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
    }

    func fetch<T: Decodable>(path: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
        guard var urlComponents = URLComponents(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Debug: Log cookies for this request
        cookieManager.logCookies(for: url, operation: "GET")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            // Handle non-success status codes
            guard (200...299).contains(httpResponse.statusCode) else {
                Logger.warning("GET \(path): Status \(httpResponse.statusCode)", category: Logger.network)
                if let responseBody = String(data: data, encoding: .utf8) {
                    Logger.debug("Response body: \(responseBody)", category: Logger.network)
                }

                // Try to decode as APIErrorResponse
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                    throw APIError.serverError(code: errorResponse.error.code, message: errorResponse.error.message)
                }

                throw APIError.invalidResponse
            }

            // Debug: Log response data
            Logger.debug("GET \(path): Status \(httpResponse.statusCode), \(data.count) bytes", category: Logger.network)
            if let responseBody = String(data: data, encoding: .utf8) {
                Logger.debug("Response: \(responseBody)", category: Logger.network)
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = Self.customDateDecodingStrategy

            do {
                let decodedData = try decoder.decode(T.self, from: data)
                return decodedData
            } catch {
                Logger.error("GET \(path): Decoding failed", error: error, category: Logger.network)
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        Logger.debug("Missing key: \(key.stringValue), context: \(context.debugDescription)", category: Logger.network)
                    case .typeMismatch(let type, let context):
                        Logger.debug("Type mismatch: expected \(type), context: \(context.debugDescription)", category: Logger.network)
                    case .valueNotFound(let type, let context):
                        Logger.debug("Value not found: \(type), context: \(context.debugDescription)", category: Logger.network)
                    case .dataCorrupted(let context):
                        Logger.debug("Data corrupted: \(context.debugDescription)", category: Logger.network)
                    @unknown default:
                        Logger.debug("Unknown decoding error", category: Logger.network)
                    }
                }
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    func post<T: Encodable, R: Decodable>(path: String, body: T) async throws -> R {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Debug: Log cookies for this request
        cookieManager.logCookies(for: url, operation: "POST")

        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(body)
        } catch {
            throw APIError.decodingError(error)
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            // Log response status for debugging
            if !(200...299).contains(httpResponse.statusCode) {
                Logger.warning("POST \(path): Status \(httpResponse.statusCode)", category: Logger.network)
                if let responseBody = String(data: data, encoding: .utf8) {
                    Logger.debug("Response body: \(responseBody)", category: Logger.network)
                }
            }

            // Try to decode response regardless of status code
            // This allows endpoints to return structured error messages in the response body
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = Self.customDateDecodingStrategy

            do {
                let decodedData = try decoder.decode(R.self, from: data)
                return decodedData
            } catch {
                // If status code indicates an error, try to decode as APIErrorResponse
                if !(200...299).contains(httpResponse.statusCode) {
                    if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                        Logger.error("POST \(path): Server error \(errorResponse.error.code)", category: Logger.network)
                        throw APIError.serverError(code: errorResponse.error.code, message: errorResponse.error.message)
                    }
                }

                Logger.error("POST \(path): Decoding failed", error: error, category: Logger.network)
                if let responseBody = String(data: data, encoding: .utf8) {
                    Logger.debug("Response body: \(responseBody)", category: Logger.network)
                }
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        Logger.debug("Missing key: \(key.stringValue), context: \(context.debugDescription)", category: Logger.network)
                    case .typeMismatch(let type, let context):
                        Logger.debug("Type mismatch: expected \(type), context: \(context.debugDescription)", category: Logger.network)
                    case .valueNotFound(let type, let context):
                        Logger.debug("Value not found: \(type), context: \(context.debugDescription)", category: Logger.network)
                    case .dataCorrupted(let context):
                        Logger.debug("Data corrupted: \(context.debugDescription)", category: Logger.network)
                    @unknown default:
                        Logger.debug("Unknown decoding error", category: Logger.network)
                    }
                }
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // POST request with no response body expected
    func post(path: String) async throws {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Debug: Log cookies for this request
        cookieManager.logCookies(for: url, operation: "POST")

        do {
            let (_, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            // Handle non-success status codes
            guard (200...299).contains(httpResponse.statusCode) else {
                Logger.warning("POST \(path): Status \(httpResponse.statusCode)", category: Logger.network)
                throw APIError.invalidResponse
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    func post<T: Encodable>(path: String, body: T) async throws {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Encode body
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(body)
        } catch {
            throw APIError.encodingError(error)
        }

        // Debug: Log cookies for this request
        cookieManager.logCookies(for: url, operation: "POST")

        do {
            let (_, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            // Handle non-success status codes
            guard (200...299).contains(httpResponse.statusCode) else {
                Logger.warning("POST \(path): Status \(httpResponse.statusCode)", category: Logger.network)
                throw APIError.invalidResponse
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    func delete<R: Decodable>(path: String) async throws -> R {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Debug: Log cookies for this request
        cookieManager.logCookies(for: url, operation: "DELETE")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = Self.customDateDecodingStrategy

            // Handle non-success status codes
            guard (200...299).contains(httpResponse.statusCode) else {
                Logger.warning("DELETE \(path): Status \(httpResponse.statusCode)", category: Logger.network)

                // Try to decode as APIErrorResponse
                if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                    throw APIError.serverError(code: errorResponse.error.code, message: errorResponse.error.message)
                }

                throw APIError.invalidResponse
            }

            do {
                let decodedData = try decoder.decode(R.self, from: data)
                return decodedData
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    func delete<T: Encodable, R: Decodable>(path: String, body: T) async throws -> R {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Debug: Log cookies for this request
        cookieManager.logCookies(for: url, operation: "DELETE")

        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(body)
        } catch {
            throw APIError.decodingError(error)
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            // Handle non-success status codes
            guard (200...299).contains(httpResponse.statusCode) else {
                Logger.warning("DELETE \(path): Status \(httpResponse.statusCode)", category: Logger.network)
                throw APIError.invalidResponse
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = Self.customDateDecodingStrategy

            do {
                let decodedData = try decoder.decode(R.self, from: data)
                return decodedData
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    func put<T: Encodable>(path: String, body: T) async throws {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Debug: Log cookies for this request
        cookieManager.logCookies(for: url, operation: "PUT")

        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(body)

            let (_, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                Logger.warning("PUT \(path): Status \(httpResponse.statusCode)", category: Logger.network)
                throw APIError.invalidResponse
            }

            Logger.info("PUT \(path): Success", category: Logger.network)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    func delete<T: Encodable>(path: String, body: T) async throws {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Debug: Log cookies for this request
        cookieManager.logCookies(for: url, operation: "DELETE")

        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(body)
        } catch {
            throw APIError.encodingError(error)
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                Logger.warning("DELETE \(path): Status \(httpResponse.statusCode)", category: Logger.network)

                // Try to decode as APIErrorResponse
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                    throw APIError.serverError(code: errorResponse.error.code, message: errorResponse.error.message)
                }

                throw APIError.invalidResponse
            }

            Logger.info("DELETE \(path): Success", category: Logger.network)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    func delete(path: String) async throws {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Debug: Log cookies for this request
        cookieManager.logCookies(for: url, operation: "DELETE")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                Logger.warning("DELETE \(path): Status \(httpResponse.statusCode)", category: Logger.network)

                // Try to decode as APIErrorResponse
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                    throw APIError.serverError(code: errorResponse.error.code, message: errorResponse.error.message)
                }

                throw APIError.invalidResponse
            }

            Logger.info("DELETE \(path): Success", category: Logger.network)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}


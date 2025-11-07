import Foundation
import Security

class APIConfig {
    static let shared = APIConfig()

    private let defaults = UserDefaults.standard
    private let baseURLKey = "api_base_url"
    private let developerModeKey = "developer_mode_enabled"
    private let defaultBaseURL = "https://oeee.cafe"

    private init() {}

    var baseURL: String {
        return defaults.string(forKey: baseURLKey) ?? defaultBaseURL
    }

    var isDeveloperModeEnabled: Bool {
        get {
            return defaults.bool(forKey: developerModeKey)
        }
        set {
            defaults.set(newValue, forKey: developerModeKey)
        }
    }

    func setBaseURL(_ url: String) throws {
        guard isValidURL(url) else {
            throw APIConfigError.invalidURL
        }

        // Clear auth state and cookies when changing URL
        clearAuthState()
        clearCookies()

        defaults.set(url, forKey: baseURLKey)
    }

    func resetToDefault() {
        clearAuthState()
        clearCookies()
        defaults.removeObject(forKey: baseURLKey)
    }

    private func isValidURL(_ urlString: String) -> Bool {
        // Check if URL starts with http:// or https://
        guard urlString.lowercased().hasPrefix("http://") || urlString.lowercased().hasPrefix("https://") else {
            return false
        }

        // Try to create URL object
        guard let url = URL(string: urlString) else {
            return false
        }

        // Check if URL has a host
        guard url.host != nil else {
            return false
        }

        return true
    }

    private func clearAuthState() {
        // Clear keychain auth state (same key used by AuthService)
        _ = KeychainHelper.shared.delete(key: "isAuthenticated")
    }

    private func clearCookies() {
        // Clear all cookies
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
    }
}

enum APIConfigError: Error {
    case invalidURL

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL format. Please enter a valid URL starting with http:// or https://"
        }
    }
}

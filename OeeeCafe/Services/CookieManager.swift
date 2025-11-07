import Foundation

/// Manages HTTP cookie storage and debugging for the app
class CookieManager {
    static let shared = CookieManager()

    private let storage = HTTPCookieStorage.shared
    private let domain = "oeee.cafe"

    private init() {
        // Configure cookie storage
        storage.cookieAcceptPolicy = .always
    }

    /// Logs stored cookies for debugging
    func logStoredCookies() {
        guard let cookies = storage.cookies else {
            Logger.debug("No cookies in storage", category: Logger.network)
            return
        }

        Logger.debug("Loaded \(cookies.count) cookies from storage", category: Logger.network)

        let domainCookies = cookies.filter { $0.domain.contains(domain) }
        if !domainCookies.isEmpty {
            Logger.debug("\(domain) cookies found: \(domainCookies.count)", category: Logger.network)
            for cookie in domainCookies {
                let expiry = cookie.expiresDate?.description ?? "session"
                Logger.debug("Cookie: \(cookie.name), domain=\(cookie.domain), expires=\(expiry), secure=\(cookie.isSecure)", category: Logger.network)
            }
        } else {
            Logger.debug("No \(domain) cookies found", category: Logger.network)
        }
    }

    /// Logs cookies for a specific URL
    func logCookies(for url: URL, operation: String) {
        if let cookies = storage.cookies(for: url) {
            Logger.debug("\(operation) \(url.path): Using \(cookies.count) cookies", category: Logger.network)
        } else {
            Logger.debug("\(operation) \(url.path): No cookies available", category: Logger.network)
        }
    }

    /// Clears all cookies from storage
    func clearAllCookies() {
        guard let cookies = storage.cookies else { return }
        for cookie in cookies {
            storage.deleteCookie(cookie)
        }
        Logger.debug("Cleared all cookies", category: Logger.network)
    }

    /// Force saves cookies to ensure persistence
    func forceSaveCookies() {
        guard let cookies = storage.cookies else { return }
        let domainCookies = cookies.filter { $0.domain.contains(domain) }

        for cookie in domainCookies {
            storage.setCookie(cookie)
            Logger.debug("Force saved cookie: \(cookie.name), expires=\(cookie.expiresDate?.description ?? "session")", category: Logger.network)
        }
    }
}

import Foundation
import Combine

class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated: Bool = false
    @Published var currentUser: CurrentUser?
    @Published var isCheckingAuth: Bool = false

    private let apiClient = APIClient.shared
    private let keychainHelper = KeychainHelper.shared
    private let cookieManager = CookieManager.shared
    private let pushService = PushNotificationService.shared
    private let authStateKey = "isAuthenticated"

    private init() {
        // Don't block init - restore session will be called after UI is rendered
    }

    // MARK: - Public Methods

    func login(loginName: String, password: String) async throws -> CurrentUser {
        let request = LoginRequest(loginName: loginName, password: password)

        let response: LoginResponse = try await apiClient.post(
            path: "/api/v1/auth/login",
            body: request
        )

        let user = response.user
        Logger.debug("Login successful - \(user.loginName)", category: Logger.auth)

        // Update state on main thread
        await MainActor.run {
            self.currentUser = user
            self.isAuthenticated = true
        }

        // Save authentication state to keychain
        let saved = keychainHelper.saveString(key: authStateKey, value: "true")
        Logger.debug("Saved auth state to keychain: \(saved)", category: Logger.auth)

        // Force save cookies to ensure persistence
        cookieManager.forceSaveCookies()

        // Request push notification permissions after successful login
        await pushService.requestPermissionsAndRegister()

        return user
    }

    func signup(loginName: String, password: String, displayName: String) async throws -> CurrentUser {
        let request = SignupRequest(
            loginName: loginName,
            password: password,
            displayName: displayName
        )

        let response: SignupResponse = try await apiClient.post(
            path: "/api/v1/auth/signup",
            body: request
        )

        let user = response.user
        Logger.debug("Signup successful - user auto-logged in: \(user.loginName)", category: Logger.auth)

        // Update state on main thread
        await MainActor.run {
            self.currentUser = user
            self.isAuthenticated = true
        }

        // Save authentication state to keychain
        let saved = keychainHelper.saveString(key: authStateKey, value: "true")
        Logger.debug("Saved auth state to keychain: \(saved)", category: Logger.auth)

        // Force save cookies to ensure persistence
        cookieManager.forceSaveCookies()

        // Request push notification permissions after successful signup
        await pushService.requestPermissionsAndRegister()

        return user
    }

    func logout() async {
        Logger.info("Starting logout process", category: Logger.auth)

        // Get the device token to include in logout request
        let deviceToken = pushService.getDeviceToken()
        if let token = deviceToken {
            Logger.debug("Found device token for logout: \(token)", category: Logger.auth)
        } else {
            Logger.warning("No device token found for logout request", category: Logger.auth)
        }

        // Call logout API with device token (if this fails, we should still try to clear local state)
        do {
            let request = LogoutRequest(deviceToken: deviceToken)
            try await apiClient.post(
                path: "/api/v1/auth/logout",
                body: request
            )
            Logger.info("Logout API call successful", category: Logger.auth)
        } catch {
            Logger.error("Logout API call failed", error: error, category: Logger.auth)
            // Continue with local logout even if API call fails
        }

        // Also delete device using the dedicated endpoint as a fallback
        // This ensures cleanup even if the logout API call failed
        Logger.debug("Attempting fallback device deletion", category: Logger.auth)
        await pushService.deleteDevice()

        // Clear state (always execute)
        Logger.debug("Clearing authentication state", category: Logger.auth)
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
        }

        // Clear keychain (always execute)
        Logger.debug("Clearing keychain", category: Logger.auth)
        let keychainCleared = keychainHelper.delete(key: authStateKey)
        if !keychainCleared {
            Logger.warning("Failed to clear keychain entry for auth state", category: Logger.auth)
        }

        // Clear cookies (always execute)
        Logger.debug("Clearing cookies", category: Logger.auth)
        cookieManager.clearAllCookies()

        Logger.info("Logout completed successfully", category: Logger.auth)
    }

    func deleteAccount(password: String) async throws {
        let request = DeleteAccountRequest(password: password)

        // Server returns 204 No Content on success, errors are thrown as APIError
        try await apiClient.delete(
            path: "/api/v1/account",
            body: request
        )

        Logger.info("Account deleted successfully", category: Logger.auth)

        // Clear state after successful deletion
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
        }

        // Clear keychain
        _ = keychainHelper.delete(key: authStateKey)

        // Clear cookies
        cookieManager.clearAllCookies()
    }

    func checkAuthStatus() async {
        Logger.debug("Checking auth status...", category: Logger.auth)
        await MainActor.run {
            self.isCheckingAuth = true
        }

        do {
            let user: CurrentUser = try await apiClient.fetch(path: "/api/v1/auth/me")

            Logger.debug("User authenticated - \(user.loginName)", category: Logger.auth)

            // Update state on main thread
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.isCheckingAuth = false
            }

            // Save state to keychain
            _ = keychainHelper.saveString(key: authStateKey, value: "true")
        } catch {
            Logger.warning("Auth check failed - \(error.localizedDescription)", category: Logger.auth)
            // Not authenticated, clear state
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
                self.isCheckingAuth = false
            }
            _ = keychainHelper.delete(key: authStateKey)
        }
    }

    func restoreSession() {
        // Log cookies for debugging (deferred to after init)
        cookieManager.logStoredCookies()

        // Check if we have saved auth state
        if let authState = keychainHelper.loadString(key: authStateKey), authState == "true" {
            Logger.debug("Found saved auth state, verifying session...", category: Logger.auth)
            // Set checking state before starting async check
            isCheckingAuth = true
            // Try to fetch current user to verify session is still valid
            Task {
                await checkAuthStatus()
            }
        } else {
            Logger.debug("No saved auth state", category: Logger.auth)
        }
    }

    // MARK: - Email Verification

    func requestEmailVerification(email: String) async throws -> RequestEmailVerificationResponse {
        let request = RequestEmailVerificationRequest(email: email)

        do {
            let response: RequestEmailVerificationResponse = try await apiClient.post(
                path: "/api/v1/account/request-verify-email",
                body: request
            )
            return response
        } catch {
            throw AuthError.networkError(error)
        }
    }

    func verifyEmailCode(challengeId: String, token: String) async throws {
        let request = VerifyEmailCodeRequest(challengeId: challengeId, token: token)

        do {
            // Server returns 204 No Content on success, so use the no-response-body POST method
            try await apiClient.post(
                path: "/api/v1/account/verify-email",
                body: request
            )
        } catch {
            throw AuthError.networkError(error)
        }
    }

}

// MARK: - Supporting Types

enum AuthError: LocalizedError {
    case loginFailed(String)
    case signupFailed(String)
    case deleteAccountFailed(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .loginFailed(let message):
            return message
        case .signupFailed(let message):
            return message
        case .deleteAccountFailed(let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

struct DeleteAccountRequest: Codable {
    let password: String
}

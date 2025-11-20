import Foundation

// MARK: - Login Request
struct LoginRequest: Codable {
    let loginName: String
    let password: String
}

// MARK: - Login Response
struct LoginResponse: Codable {
    let user: CurrentUser
}

// MARK: - Current User
struct CurrentUser: Codable, Identifiable {
    let id: String
    let loginName: String
    let displayName: String
    let email: String?
    let emailVerifiedAt: String?
    let bannerId: String?
    let preferredLanguage: String?
}

// MARK: - Signup Request
struct SignupRequest: Codable {
    let loginName: String
    let password: String
    let displayName: String
}

// MARK: - Signup Response
typealias SignupResponse = LoginResponse

// MARK: - Logout Request
struct LogoutRequest: Codable {
    let deviceToken: String?
}

// MARK: - Email Verification
struct RequestEmailVerificationRequest: Codable {
    let email: String
}

struct RequestEmailVerificationResponse: Codable {
    let challengeId: String
    let email: String
    let expiresInSeconds: Int
}

struct VerifyEmailCodeRequest: Codable {
    let challengeId: String
    let token: String
}

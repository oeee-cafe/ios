import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var showLogoutConfirmation = false
    @State private var showClearCacheConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var deleteAccountPassword = ""
    @State private var isDeleting = false
    @State private var deleteError: String?
    @State private var cacheSize: UInt = 0
    @State private var isLoadingCacheSize = false

    // Developer mode
    @State private var tapCount = 0
    @State private var isDeveloperMode = APIConfig.shared.isDeveloperModeEnabled
    @State private var showDeveloperModeToast = false
    @State private var customServerURL = ""
    @State private var showServerURLError = false
    @State private var serverURLError = ""

    // Email verification
    @State private var showEmailVerificationSheet = false
    @State private var verificationStep: EmailVerificationStep = .enterEmail
    @State private var emailInput = ""
    @State private var verificationCode = ""
    @State private var isRequestingVerification = false
    @State private var isVerifyingCode = false
    @State private var isResendingCode = false
    @State private var emailVerificationError: String?
    @State private var challengeId: String?
    @State private var expiresInSeconds = 300
    @State private var showSuccessAlert = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    if let user = authService.currentUser {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.displayName)
                                .font(.headline)
                            Text("@\(user.loginName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }

                // Email Verification Section
                if let user = authService.currentUser {
                    Section(header: Text("email_verification.section_title".localized)) {
                        VStack(alignment: .leading, spacing: 8) {
                            if let email = user.email {
                                HStack {
                                    Text(email)
                                        .font(.subheadline)
                                    Spacer()
                                    if user.emailVerifiedAt != nil {
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                            Text("email_verification.verified".localized)
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                    } else {
                                        Text("email_verification.not_verified".localized)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                            } else {
                                Text("email_verification.no_email".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)

                        Button(action: {
                            // Only pre-fill if email is not verified
                            if user.emailVerifiedAt == nil {
                                emailInput = user.email ?? ""
                            } else {
                                emailInput = ""
                            }
                            verificationStep = .enterEmail
                            emailVerificationError = nil
                            showEmailVerificationSheet = true
                        }) {
                            HStack {
                                Image(systemName: "envelope")
                                Text(user.email == nil || user.emailVerifiedAt == nil
                                    ? "email_verification.verify_button".localized
                                    : "email_verification.change_button".localized)
                            }
                        }
                    }
                }

                Section(header: Text("settings.storage".localized)) {
                    HStack {
                        Text("settings.image_cache".localized)
                        Spacer()
                        if isLoadingCacheSize {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                        } else {
                            Text(formatBytes(cacheSize))
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: {
                        showClearCacheConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("settings.clear_cache".localized)
                        }
                    }
                    .foregroundColor(.red)
                }

                Section(header: Text("settings.account".localized)) {
                    Button(role: .destructive, action: {
                        showDeleteAccountConfirmation = true
                        deleteAccountPassword = ""
                        deleteError = nil
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("settings.delete_account".localized)
                        }
                    }
                }

                // Advanced Settings (only visible in developer mode)
                if isDeveloperMode {
                    Section(header: Text("settings.advanced".localized)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("settings.server_url".localized)
                                .font(.subheadline)
                            TextField("https://oeee.cafe", text: $customServerURL)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)

                            HStack {
                                Text("\("settings.current".localized) \(APIConfig.shared.baseURL)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)

                        HStack {
                            Button(action: {
                                saveServerURL()
                            }) {
                                Text("common.save".localized)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)

                            Button(action: {
                                resetServerURL()
                            }) {
                                Text("settings.reset_to_default".localized)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                Section {
                    Button(role: .destructive, action: {
                        showLogoutConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("settings.sign_out".localized)
                        }
                    }
                }

                // Version section with tap gesture
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text("common.app_name_lowercase".localized)
                                .foregroundColor(.secondary)
                                .font(.caption)
                            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                                Text("common.version".localized(version, build))
                                    .foregroundColor(.secondary)
                                    .font(.caption2)
                            }
                        }
                        .onTapGesture {
                            handleVersionTap()
                        }
                        Spacer()
                    }
                }
            }
            .onAppear {
                loadCacheSize()
                customServerURL = APIConfig.shared.baseURL
            }
            .navigationTitle("settings.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .overlay(
                Group {
                    if showDeveloperModeToast {
                        VStack {
                            Text("settings.developer_mode_enabled".localized)
                                .padding()
                                .background(Color(uiColor: .systemGray))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .padding(.top, 50)
                            Spacer()
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            )
            .alert("settings.server_url_error".localized, isPresented: $showServerURLError) {
                Button("common.ok".localized, role: .cancel) {}
            } message: {
                Text(serverURLError)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("settings.sign_out_confirm".localized, isPresented: $showLogoutConfirmation) {
                Button("settings.sign_out".localized, role: .destructive) {
                    Task {
                        await authService.logout()
                        dismiss()
                    }
                }
                Button("common.cancel".localized, role: .cancel) {}
            }
            .confirmationDialog("settings.clear_cache_confirm".localized, isPresented: $showClearCacheConfirmation) {
                Button("settings.clear_cache".localized, role: .destructive) {
                    clearCache()
                }
                Button("common.cancel".localized, role: .cancel) {}
            } message: {
                Text("settings.clear_cache_message".localized(formatBytes(cacheSize)))
            }
            .alert("settings.delete_account_confirm".localized, isPresented: $showDeleteAccountConfirmation) {
                SecureField("settings.password".localized, text: $deleteAccountPassword)
                Button("settings.delete_account".localized, role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
                Button("common.cancel".localized, role: .cancel) {
                    deleteAccountPassword = ""
                    deleteError = nil
                }
            } message: {
                VStack {
                    Text("settings.delete_account_warning".localized)
                    if let error = deleteError {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .sheet(isPresented: $showEmailVerificationSheet) {
                EmailVerificationSheet(
                    isPresented: $showEmailVerificationSheet,
                    currentStep: $verificationStep,
                    email: $emailInput,
                    code: $verificationCode,
                    isRequestingCode: $isRequestingVerification,
                    isVerifyingCode: $isVerifyingCode,
                    isResendingCode: $isResendingCode,
                    errorMessage: $emailVerificationError,
                    expiresInSeconds: $expiresInSeconds,
                    onRequestCode: { email in
                        Task {
                            await requestEmailVerification(email: email)
                        }
                    },
                    onVerifyCode: { code in
                        Task {
                            await verifyCode(code: code)
                        }
                    },
                    onResendCode: {
                        Task {
                            await resendCode()
                        }
                    }
                )
            }
            .alert("email_verification.success_title".localized, isPresented: $showSuccessAlert) {
                Button("common.ok".localized, role: .cancel) {}
            } message: {
                Text("email_verification.success_message".localized)
            }
        }
    }

    private func loadCacheSize() {
        isLoadingCacheSize = true
        KingfisherConfig.getCacheSize { size in
            cacheSize = size
            isLoadingCacheSize = false
        }
    }

    private func clearCache() {
        KingfisherConfig.clearCache {
            loadCacheSize()
        }
    }

    private func deleteAccount() async {
        guard !deleteAccountPassword.isEmpty else {
            deleteError = "settings.password_required".localized
            showDeleteAccountConfirmation = true
            return
        }

        isDeleting = true
        do {
            try await authService.deleteAccount(password: deleteAccountPassword)
            dismiss()
        } catch {
            deleteError = error.localizedDescription
            deleteAccountPassword = ""
            showDeleteAccountConfirmation = true
        }
        isDeleting = false
    }

    private func formatBytes(_ bytes: UInt) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private func handleVersionTap() {
        tapCount += 1

        if tapCount >= 10 && !isDeveloperMode {
            // Enable developer mode
            withAnimation {
                isDeveloperMode = true
                APIConfig.shared.isDeveloperModeEnabled = true
                showDeveloperModeToast = true
            }

            // Hide toast after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showDeveloperModeToast = false
                }
            }

            // Reset tap count
            tapCount = 0
        }

        // Reset tap count after 2 seconds of inactivity
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if tapCount < 10 {
                tapCount = 0
            }
        }
    }

    private func saveServerURL() {
        do {
            try APIConfig.shared.setBaseURL(customServerURL)
            serverURLError = "settings.server_url_updated".localized
            showServerURLError = true
        } catch {
            if let configError = error as? APIConfigError {
                serverURLError = configError.localizedDescription
            } else {
                serverURLError = error.localizedDescription
            }
            showServerURLError = true
        }
    }

    private func resetServerURL() {
        APIConfig.shared.resetToDefault()
        customServerURL = APIConfig.shared.baseURL
        serverURLError = "settings.server_url_reset".localized
        showServerURLError = true
    }

    // MARK: - Email Verification Methods

    private func requestEmailVerification(email: String) async {
        isRequestingVerification = true
        emailVerificationError = nil

        do {
            let response = try await authService.requestEmailVerification(email: email)

            await MainActor.run {
                if response.success, let challengeId = response.challengeId {
                    self.challengeId = challengeId
                    self.expiresInSeconds = response.expiresInSeconds ?? 300
                    self.verificationStep = .enterCode
                } else {
                    emailVerificationError = response.error ?? "error.failed_request_verification".localized
                }
                isRequestingVerification = false
            }
        } catch {
            await MainActor.run {
                emailVerificationError = error.localizedDescription
                isRequestingVerification = false
            }
        }
    }

    private func verifyCode(code: String) async {
        guard let challengeId = challengeId else { return }

        isVerifyingCode = true
        emailVerificationError = nil

        do {
            let response = try await authService.verifyEmailCode(challengeId: challengeId, token: code)

            await MainActor.run {
                if response.success {
                    // Update the current user's email and emailVerifiedAt fields locally
                    if let user = authService.currentUser {
                        let updatedUser = CurrentUser(
                            id: user.id,
                            loginName: user.loginName,
                            displayName: user.displayName,
                            email: self.emailInput,
                            emailVerifiedAt: ISO8601DateFormatter().string(from: Date()),
                            bannerId: user.bannerId,
                            preferredLanguage: user.preferredLanguage
                        )
                        authService.currentUser = updatedUser
                    }

                    self.showEmailVerificationSheet = false
                    self.challengeId = nil
                    self.verificationCode = ""
                    self.verificationStep = .enterEmail
                    self.showSuccessAlert = true
                } else {
                    emailVerificationError = response.error ?? "error.verification_failed".localized
                }
                isVerifyingCode = false
            }
        } catch {
            await MainActor.run {
                emailVerificationError = error.localizedDescription
                isVerifyingCode = false
            }
        }
    }

    private func resendCode() async {
        isResendingCode = true
        emailVerificationError = nil

        do {
            let response = try await authService.requestEmailVerification(email: emailInput)

            await MainActor.run {
                if response.success, let newChallengeId = response.challengeId {
                    self.challengeId = newChallengeId
                    self.expiresInSeconds = response.expiresInSeconds ?? 300
                } else {
                    emailVerificationError = response.error ?? "error.failed_resend_code".localized
                }
                isResendingCode = false
            }
        } catch {
            await MainActor.run {
                emailVerificationError = error.localizedDescription
                isResendingCode = false
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService.shared)
}

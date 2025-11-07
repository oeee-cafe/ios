import SwiftUI

// MARK: - Email Verification State
enum EmailVerificationStep {
    case enterEmail
    case enterCode
}

// MARK: - Unified Email Verification Sheet
struct EmailVerificationSheet: View {
    @Binding var isPresented: Bool
    @Binding var currentStep: EmailVerificationStep
    @Binding var email: String
    @Binding var code: String
    @Binding var isRequestingCode: Bool
    @Binding var isVerifyingCode: Bool
    @Binding var isResendingCode: Bool
    @Binding var errorMessage: String?
    @Binding var expiresInSeconds: Int
    let onRequestCode: (String) -> Void
    let onVerifyCode: (String) -> Void
    let onResendCode: () -> Void

    @State private var emailError: String?
    @State private var codeError: String?
    @State private var timeRemaining: Int = 0
    @State private var timer: Timer?

    var body: some View {
        NavigationView {
            Form {
                switch currentStep {
                case .enterEmail:
                    emailInputSection
                case .enterCode:
                    codeInputSection
                }
            }
            .navigationTitle(currentStep == .enterEmail
                ? "email_verification.title".localized
                : "email_verification.verify_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        resetAndDismiss()
                    }
                    .disabled(isRequestingCode || isVerifyingCode)
                }
            }
            .onChange(of: currentStep) { newStep in
                if newStep == .enterCode {
                    timeRemaining = expiresInSeconds
                    startTimer()
                }
            }
            .onChange(of: expiresInSeconds) { _ in
                if currentStep == .enterCode {
                    timeRemaining = expiresInSeconds
                    startTimer()
                }
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }

    // MARK: - Email Input Section
    private var emailInputSection: some View {
        Group {
            Section {
                Text("email_verification.description".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField("email_verification.email_placeholder".localized, text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .disabled(isRequestingCode)

                if let error = emailError ?? errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            Section {
                Button(action: {
                    validateAndRequestCode()
                }) {
                    HStack {
                        Spacer()
                        if isRequestingCode {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Text("email_verification.send_code".localized)
                        }
                        Spacer()
                    }
                }
                .disabled(isRequestingCode || email.isEmpty)
            }
        }
    }

    // MARK: - Code Input Section
    private var codeInputSection: some View {
        Group {
            Section {
                Text(String(format: "email_verification.code_sent_to".localized, email))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField("email_verification.code_placeholder".localized, text: $code)
                    .keyboardType(.numberPad)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .disabled(isVerifyingCode)
                    .onChange(of: code) { newValue in
                        // Only allow digits and max 6 characters
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered.count <= 6 {
                            code = filtered
                        } else {
                            code = String(filtered.prefix(6))
                        }
                        codeError = nil
                    }

                HStack {
                    Image(systemName: timeRemaining > 0 ? "clock" : "exclamationmark.triangle")
                        .foregroundColor(timeRemaining > 0 ? .secondary : .red)

                    Text(timeRemaining > 0
                        ? String(format: "email_verification.expires_in".localized, formatTime(timeRemaining))
                        : "email_verification.code_expired".localized)
                        .font(.caption)
                        .foregroundColor(timeRemaining > 0 ? .secondary : .red)
                }

                if let error = codeError ?? errorMessage {
                    Text(localizeError(error))
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            Section {
                Button(action: {
                    validateAndVerifyCode()
                }) {
                    HStack {
                        Spacer()
                        if isVerifyingCode {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Text("email_verification.verify".localized)
                        }
                        Spacer()
                    }
                }
                .disabled(isVerifyingCode || code.count != 6)

                Button(action: onResendCode) {
                    HStack {
                        Spacer()
                        if isResendingCode {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Text("email_verification.resend_code".localized)
                        }
                        Spacer()
                    }
                }
                .disabled(isResendingCode || isVerifyingCode)
            }
        }
    }

    // MARK: - Helper Methods
    private func validateAndRequestCode() {
        emailError = nil

        guard !email.isEmpty else {
            emailError = "Email is required"
            return
        }

        guard email.contains("@") && email.contains(".") else {
            emailError = "Invalid email format"
            return
        }

        onRequestCode(email)
    }

    private func validateAndVerifyCode() {
        codeError = nil

        guard code.count == 6 else {
            codeError = "Code must be 6 digits"
            return
        }

        onVerifyCode(code)
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func localizeError(_ error: String) -> String {
        switch error {
        case "TOKEN_MISMATCH":
            return "email_verification.error.token_mismatch".localized
        case "TOKEN_EXPIRED":
            return "email_verification.error.token_expired".localized
        case "CHALLENGE_NOT_FOUND":
            return "email_verification.error.challenge_not_found".localized
        default:
            return error
        }
    }

    private func resetAndDismiss() {
        currentStep = .enterEmail
        code = ""
        emailError = nil
        codeError = nil
        errorMessage = nil
        timer?.invalidate()
        isPresented = false
    }
}

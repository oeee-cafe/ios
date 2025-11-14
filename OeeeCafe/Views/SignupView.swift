import SwiftUI

struct SignupView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss

    @State private var loginName = ""
    @State private var displayName = ""
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSettings = false
    @FocusState private var focusedField: Field?

    enum Field {
        case loginName
        case displayName
        case password
        case passwordConfirm
    }

    var body: some View {
        VStack(spacing: 24) {
            // Logo/Header
            Text(NSLocalizedString("auth.signup_title", comment: "Sign Up"))
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 40)

            // Signup Form
            VStack(spacing: 16) {
                TextField(NSLocalizedString("auth.username", comment: "Username"), text: $loginName)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .loginName)
                    .onSubmit {
                        focusedField = .displayName
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(10)

                TextField(NSLocalizedString("auth.display_name", comment: "Display Name"), text: $displayName)
                    .textContentType(.name)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .displayName)
                    .onSubmit {
                        focusedField = .password
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(10)

                SecureField(NSLocalizedString("auth.password", comment: "Password"), text: $password)
                    .textContentType(.newPassword)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .password)
                    .onSubmit {
                        focusedField = .passwordConfirm
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(10)

                SecureField(NSLocalizedString("auth.confirm_password", comment: "Confirm Password"), text: $passwordConfirm)
                    .textContentType(.newPassword)
                    .submitLabel(.go)
                    .focused($focusedField, equals: .passwordConfirm)
                    .onSubmit {
                        if isFormValid && !isLoading {
                            // Immediately hide keyboard before any async work
                            focusedField = nil
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first {
                                window.endEditing(true)
                            }

                            Task {
                                await handleSignup()
                            }
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(10)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button(action: {
                    // Immediately hide keyboard before any async work
                    focusedField = nil
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.endEditing(true)
                    }

                    Task {
                        await handleSignup()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(NSLocalizedString("auth.signup_button", comment: "Sign Up"))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(isFormValid ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(!isFormValid || isLoading)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            dismissKeyboard()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(authService)
        }
    }

    private var isFormValid: Bool {
        !loginName.isEmpty && !displayName.isEmpty && !password.isEmpty && !passwordConfirm.isEmpty
    }

    private func dismissKeyboard() {
        // Force keyboard dismissal on main thread
        DispatchQueue.main.async {
            self.focusedField = nil
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

            // Additional forced dismissal for autofill keyboard
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.endEditing(true)
            }
        }
    }

    private func handleSignup() async {
        errorMessage = nil

        // Validate passwords match
        if password != passwordConfirm {
            errorMessage = NSLocalizedString("auth.error_passwords_not_match", comment: "Passwords do not match")
            return
        }

        isLoading = true

        do {
            _ = try await authService.signup(
                loginName: loginName,
                password: password,
                displayName: displayName
            )
            // Signup successful - user is auto-logged in
            // ContentView will automatically switch to home view due to @Published isAuthenticated change
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        } catch let error as AuthError {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = NSLocalizedString("auth.error_unexpected", comment: "An unexpected error occurred")
                isLoading = false
            }
        }
    }
}

#Preview {
    SignupView()
}

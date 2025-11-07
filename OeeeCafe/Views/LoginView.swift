import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService

    @State private var loginName = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSettings = false
    @FocusState private var focusedField: Field?

    enum Field {
        case username
        case password
    }

    var body: some View {
        VStack(spacing: 24) {
            // Logo/Header
            Text(NSLocalizedString("auth.app_name", comment: "App name"))
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 40)

            // Login Form
            VStack(spacing: 16) {
                TextField(NSLocalizedString("auth.username", comment: "Username"), text: $loginName)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .username)
                    .onSubmit {
                        focusedField = .password
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(10)

                SecureField(NSLocalizedString("auth.password", comment: "Password"), text: $password)
                    .textContentType(.password)
                    .submitLabel(.go)
                    .focused($focusedField, equals: .password)
                    .onSubmit {
                        if isFormValid && !isLoading {
                            Task {
                                await handleLogin()
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
                    focusedField = nil // Dismiss keyboard
                    Task {
                        await handleLogin()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(NSLocalizedString("auth.login_button", comment: "Log In"))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(isFormValid ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(!isFormValid || isLoading)

                // Sign Up navigation link
                NavigationLink(destination: SignupView().environmentObject(authService)) {
                    Text(NSLocalizedString("auth.signup_link", comment: "Don't have an account? Sign Up"))
                        .font(.body)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            focusedField = nil
        }
        .navigationTitle(NSLocalizedString("auth.login_title", comment: "Log In"))
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
        !loginName.isEmpty && !password.isEmpty
    }

    private func handleLogin() async {
        errorMessage = nil
        isLoading = true

        do {
            _ = try await authService.login(loginName: loginName, password: password)
            // Login successful - ContentView will automatically switch to ProfileView
            // due to @Published isAuthenticated change
            await MainActor.run {
                isLoading = false
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
    LoginView()
}

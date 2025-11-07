import SwiftUI

/// Reusable toolbar content for authenticated views
/// Shows profile + settings on leading, draw button on trailing
struct AppToolbar: ToolbarContent {
    @ObservedObject var authService: AuthService
    @Binding var showSettings: Bool
    @Binding var showDimensionPicker: Bool

    var body: some ToolbarContent {
        if authService.isAuthenticated, let user = authService.currentUser {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 12) {
                    NavigationLink(destination: ProfileView(loginName: user.loginName)) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title3)
                    }

                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gear")
                            .font(.title3)
                    }
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showDimensionPicker = true
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.title3)
                }
            }
        }
    }
}

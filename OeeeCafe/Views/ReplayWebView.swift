import SwiftUI
import WebKit

struct ReplayWebView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = true

    let postId: String

    var body: some View {
        NavigationStack {
            ZStack {
                ReplayWebViewContainer(postId: postId, isLoading: $isLoading)

                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("common.loading".localized)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(uiColor: .systemBackground))
                }
            }
            .navigationTitle("Replay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ReplayWebViewContainer: UIViewRepresentable {
    let postId: String
    @Binding var isLoading: Bool

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let url = URL(string: "\(APIConfig.shared.baseURL)/posts/\(postId)/replay/mobile")!
        let request = URLRequest(url: url)
        uiView.load(request)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: ReplayWebViewContainer

        init(_ parent: ReplayWebViewContainer) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}

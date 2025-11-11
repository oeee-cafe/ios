import SwiftUI
import WebKit

struct BannerDrawWebView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = true
    var onBannerComplete: ((String, String) -> Void)?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            NavigationStack {
                ZStack {
                    BannerWebViewContainer(
                        isLoading: $isLoading,
                        onBannerComplete: onBannerComplete,
                        dismiss: dismiss
                    )

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
                .navigationTitle("Draw Banner")
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
}

struct BannerWebViewContainer: UIViewRepresentable {
    @Binding var isLoading: Bool
    var onBannerComplete: ((String, String) -> Void)?
    var dismiss: DismissAction

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()

        // Performance optimizations
        configuration.suppressesIncrementalRendering = false
        configuration.allowsInlineMediaPlayback = true

        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences

        // Add message handler for native bridge
        configuration.userContentController.add(context.coordinator, name: "oeee")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        webView.scrollView.isScrollEnabled = true
        webView.allowsBackForwardNavigationGestures = false

        // Sync cookies and load page
        syncCookiesToWebView(webView) {
            self.loadBannerDrawPage(webView)
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // No updates needed
    }

    private func loadBannerDrawPage(_ webView: WKWebView) {
        guard let url = URL(string: "\(APIConfig.shared.baseURL)/banners/draw/mobile") else {
            Logger.error("Invalid banner draw URL", category: Logger.network)
            return
        }

        var request = URLRequest(url: url)
        Logger.debug("BannerDrawWebView: Loading URL=\(url)", category: Logger.network)
        webView.load(request)
    }

    private func syncCookiesToWebView(_ webView: WKWebView, completion: @escaping () -> Void) {
        guard let cookies = HTTPCookieStorage.shared.cookies else {
            Logger.debug("BannerDrawWebView: No cookies to sync", category: Logger.network)
            completion()
            return
        }

        Logger.debug("BannerDrawWebView: Syncing \(cookies.count) cookies to WebView", category: Logger.network)

        let dispatchGroup = DispatchGroup()

        for cookie in cookies {
            dispatchGroup.enter()
            webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            Logger.debug("BannerDrawWebView: All cookies synced", category: Logger.network)
            completion()
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: BannerWebViewContainer

        init(_ parent: BannerWebViewContainer) {
            self.parent = parent
        }

        // Handle navigation events
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Logger.debug("BannerDrawWebView: Page loaded", category: Logger.network)
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Logger.error("BannerDrawWebView: Navigation failed", error: error, category: Logger.network)
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }

        // Handle JavaScript messages from Neo painter
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "oeee",
                  let dict = message.body as? [String: Any],
                  let type = dict["type"] as? String else {
                Logger.warning("BannerDrawWebView: Invalid message format", category: Logger.network)
                return
            }

            Logger.debug("BannerDrawWebView: Received message type=\(type)", category: Logger.network)

            switch type {
            case "banner_complete":
                guard let bannerId = dict["bannerId"] as? String,
                      let imageUrl = dict["imageUrl"] as? String else {
                    Logger.error("BannerDrawWebView: Missing bannerId or imageUrl in banner_complete message", category: Logger.network)
                    return
                }

                Logger.info("BannerDrawWebView: Banner completed - bannerId=\(bannerId)", category: Logger.network)

                DispatchQueue.main.async {
                    self.parent.onBannerComplete?(bannerId, imageUrl)
                    self.parent.dismiss()
                }

            default:
                Logger.warning("BannerDrawWebView: Unknown message type=\(type)", category: Logger.network)
            }
        }

        // Handle JavaScript alerts
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            Logger.debug("BannerDrawWebView: JavaScript alert: \(message)", category: Logger.network)

            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "common.ok".localized, style: .default) { _ in
                completionHandler()
            })

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                var presenter = rootViewController
                while let presented = presenter.presentedViewController {
                    presenter = presented
                }
                presenter.present(alert, animated: true)
            } else {
                completionHandler()
            }
        }
    }
}

#Preview {
    BannerDrawWebView()
}

import SwiftUI
import WebKit

struct DrawWebView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = true

    let width: Int
    let height: Int
    let tool: DrawingTool
    let communityId: String?
    let parentPostId: String?
    var onDrawingComplete: ((String, String?, String) -> Void)?

    init(
        width: Int = 300,
        height: Int = 300,
        tool: DrawingTool = .neo,
        communityId: String? = nil,
        parentPostId: String? = nil,
        onDrawingComplete: ((String, String?, String) -> Void)? = nil
    ) {
        self.width = width
        self.height = height
        self.tool = tool
        self.communityId = communityId
        self.parentPostId = parentPostId
        self.onDrawingComplete = onDrawingComplete
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            NavigationStack {
                ZStack {
                    WebViewContainer(
                        width: width,
                        height: height,
                        tool: tool,
                        communityId: communityId,
                        parentPostId: parentPostId,
                        isLoading: $isLoading,
                        onDrawingComplete: onDrawingComplete,
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
                .navigationTitle("draw.title".localized)
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

struct WebViewContainer: UIViewRepresentable {
    let width: Int
    let height: Int
    let tool: DrawingTool
    let communityId: String?
    let parentPostId: String?
    @Binding var isLoading: Bool
    var onDrawingComplete: ((String, String?, String) -> Void)?
    var dismiss: DismissAction

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()

        // Performance optimizations
        configuration.suppressesIncrementalRendering = false // Allow progressive rendering
        configuration.allowsInlineMediaPlayback = true

        // Preferences for better performance
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences

        // Add message handler for native bridge
        configuration.userContentController.add(context.coordinator, name: "oeee")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        // Performance settings
        webView.scrollView.isScrollEnabled = true
        webView.allowsBackForwardNavigationGestures = false

        // Sync cookies and load page
        syncCookiesToWebView(webView) {
            self.loadDrawPage(webView)
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // No updates needed
    }

    private func loadDrawPage(_ webView: WKWebView) {
        guard let url = URL(string: "\(APIConfig.shared.baseURL)/draw/mobile") else {
            Logger.error("Invalid draw URL", category: Logger.network)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var postData = "width=\(width)&height=\(height)&tool=\(tool.rawValue)"
        if let communityId = communityId {
            postData += "&community_id=\(communityId)"
        }
        if let parentPostId = parentPostId {
            postData += "&parent_post_id=\(parentPostId)"
        }
        request.httpBody = postData.data(using: .utf8)

        Logger.debug("DrawWebView: Loading URL=\(url) with POST data=\(postData)", category: Logger.network)
        webView.load(request)
    }

    private func syncCookiesToWebView(_ webView: WKWebView, completion: @escaping () -> Void) {
        guard let cookies = HTTPCookieStorage.shared.cookies else {
            Logger.debug("DrawWebView: No cookies to sync", category: Logger.network)
            completion()
            return
        }

        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let baseURLHost = URL(string: APIConfig.shared.baseURL)?.host ?? "oeee.cafe"
        let oeeeCookies = cookies.filter { $0.domain.contains(baseURLHost) }

        Logger.debug("DrawWebView: Syncing \(oeeeCookies.count) oeee.cafe cookies to webview", category: Logger.network)

        // Use Task to run async operations without blocking
        Task { @MainActor in
            await withTaskGroup(of: Void.self) { group in
                for cookie in oeeeCookies {
                    group.addTask { @MainActor in
                        await withCheckedContinuation { continuation in
                            cookieStore.setCookie(cookie) {
                                continuation.resume()
                            }
                        }
                    }
                }
            }

            Logger.debug("DrawWebView: All cookies synced", category: Logger.network)
            completion()
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebViewContainer

        init(_ parent: WebViewContainer) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            Logger.debug("DrawWebView: Navigation to URL=\(url.absoluteString)", category: Logger.network)

            // Only handle link clicks in the main frame
            // Ignore iframe navigations and other navigation types
            guard navigationAction.targetFrame?.isMainFrame == true,
                  navigationAction.navigationType == .linkActivated else {
                decisionHandler(.allow)
                return
            }

            // Check if this is an external link (not the configured base URL domain)
            let baseURLHost = URL(string: APIConfig.shared.baseURL)?.host ?? "oeee.cafe"
            if let host = url.host, !host.contains(baseURLHost) {
                // Open in external browser
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            // Allow navigation within the configured domain
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
            if let url = webView.url {
                Logger.debug("DrawWebView: Finished loading URL=\(url.absoluteString)", category: Logger.network)
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
            Logger.error("WebView navigation failed", error: error, category: Logger.app)
        }

        // WKUIDelegate - Handle JavaScript alerts
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completionHandler()
            })

            if let topViewController = getTopViewController() {
                topViewController.present(alert, animated: true)
            } else {
                completionHandler()
            }
        }

        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completionHandler(false)
            })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completionHandler(true)
            })

            if let topViewController = getTopViewController() {
                topViewController.present(alert, animated: true)
            } else {
                completionHandler(false)
            }
        }

        // Handle new window requests (e.g., target="_blank" links)
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // If a link is trying to open in a new window, open it in external browser instead
            if let url = navigationAction.request.url {
                let baseURLHost = URL(string: APIConfig.shared.baseURL)?.host ?? "oeee.cafe"
                if let host = url.host, !host.contains(baseURLHost) {
                    // External link - open in Safari
                    UIApplication.shared.open(url)
                } else {
                    // Internal link - load in current webview
                    webView.load(navigationAction.request)
                }
            }
            return nil
        }

        // Helper function to get the topmost view controller
        private func getTopViewController() -> UIViewController? {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let keyWindow = windowScene.keyWindow,
                  let rootViewController = keyWindow.rootViewController else {
                return nil
            }

            return getTopViewController(from: rootViewController)
        }

        private func getTopViewController(from viewController: UIViewController) -> UIViewController {
            if let presented = viewController.presentedViewController {
                return getTopViewController(from: presented)
            }

            if let navigationController = viewController as? UINavigationController {
                if let visible = navigationController.visibleViewController {
                    return getTopViewController(from: visible)
                }
            }

            if let tabBarController = viewController as? UITabBarController {
                if let selected = tabBarController.selectedViewController {
                    return getTopViewController(from: selected)
                }
            }

            return viewController
        }

        // WKScriptMessageHandler
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "oeee",
                  let body = message.body as? [String: Any],
                  let type = body["type"] as? String,
                  type == "drawing_complete",
                  let postId = body["postId"] as? String,
                  let imageUrl = body["imageUrl"] as? String else {
                Logger.debug("Received invalid message from webview: \(message.body)", category: Logger.app)
                return
            }

            // communityId is optional for personal posts
            let communityId = body["communityId"] as? String

            Logger.debug("Drawing complete: postId=\(postId), communityId=\(communityId ?? "nil"), imageUrl=\(imageUrl)", category: Logger.app)

            // Clear the drawing session (only for legacy Neo painter)
            if let webView = message.webView {
                webView.evaluateJavaScript("if (typeof Neo !== 'undefined' && Neo.painter) { Neo.painter.clearSession(); }") { _, error in
                    if let error = error {
                        Logger.error("Failed to clear drawing session", error: error, category: Logger.app)
                    }
                }
            }

            DispatchQueue.main.async {
                self.parent.onDrawingComplete?(postId, communityId, imageUrl)
                self.parent.dismiss()
            }
        }
    }
}

#Preview {
    DrawWebView()
}

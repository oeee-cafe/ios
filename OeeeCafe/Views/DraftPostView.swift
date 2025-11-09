import SwiftUI

struct DraftPostView: View {
    let postId: String
    let communityId: String?
    let imageUrl: String
    let onPublished: () -> Void
    let onCancel: () -> Void

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var hashtags: String = ""
    @State private var isSensitive: Bool = false
    @State private var allowRelay: Bool = true
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Preview")) {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(maxHeight: 200)
                }

                Section(header: Text("Post Details")) {
                    TextField("Title", text: $title)
                        .autocapitalization(.sentences)

                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if content.isEmpty {
                                    Text("Description (optional)")
                                        .foregroundColor(.gray.opacity(0.6))
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                }
                            },
                            alignment: .topLeading
                        )

                    TextField("post.hashtags_placeholder".localized, text: $hashtags)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }

                Section {
                    Toggle("drafts.sensitive_content".localized, isOn: $isSensitive)
                    Toggle("drafts.allow_relay".localized, isOn: $allowRelay)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Publish Drawing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .disabled(isSubmitting)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Publish") {
                        publishPost()
                    }
                    .disabled(title.isEmpty || isSubmitting)
                }
            }
            .disabled(isSubmitting)
            .overlay(
                Group {
                    if isSubmitting {
                        ProgressView("Publishing...")
                            .padding()
                            .background(Color(UIColor.systemBackground).opacity(0.9))
                            .cornerRadius(10)
                    }
                }
            )
        }
    }

    private func publishPost() {
        guard !title.isEmpty else { return }

        isSubmitting = true
        errorMessage = nil

        // Prepare form data
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "post_id", value: postId),
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "content", value: content)
        ]

        if !hashtags.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            components.queryItems?.append(URLQueryItem(name: "hashtags", value: hashtags))
        }

        if isSensitive {
            components.queryItems?.append(URLQueryItem(name: "is_sensitive", value: "on"))
        }
        if allowRelay {
            components.queryItems?.append(URLQueryItem(name: "allow_relay", value: "on"))
        }

        guard let formBody = components.query?.data(using: .utf8) else {
            errorMessage = "Failed to prepare request"
            isSubmitting = false
            return
        }

        // Create request
        guard let url = URL(string: "\(APIConfig.shared.baseURL)/posts/publish") else {
            errorMessage = "Invalid URL"
            isSubmitting = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formBody

        // Use shared HTTP cookie storage
        if let cookies = HTTPCookieStorage.shared.cookies(for: url) {
            let headers = HTTPCookie.requestHeaderFields(with: cookies)
            for (name, value) in headers {
                request.setValue(value, forHTTPHeaderField: name)
            }
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false

                if let error = error {
                    errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    errorMessage = "Invalid response"
                    return
                }

                if httpResponse.statusCode == 200 || httpResponse.statusCode == 303 {
                    // Success
                    onPublished()
                } else {
                    errorMessage = "Failed to publish (Status \(httpResponse.statusCode))"
                }
            }
        }.resume()
    }
}

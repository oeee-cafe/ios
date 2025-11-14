import SwiftUI

struct EditPostView: View {
    let postId: String
    let initialTitle: String
    let initialContent: String
    let initialHashtags: String
    let initialIsSensitive: Bool
    let initialAllowRelay: Bool
    let onSaved: () -> Void
    let onCancel: () -> Void

    @State private var title: String
    @State private var content: String
    @State private var hashtags: String
    @State private var isSensitive: Bool
    @State private var allowRelay: Bool
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?

    private let service = PostService.shared

    init(
        postId: String,
        initialTitle: String,
        initialContent: String,
        initialHashtags: String,
        initialIsSensitive: Bool,
        initialAllowRelay: Bool,
        onSaved: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.postId = postId
        self.initialTitle = initialTitle
        self.initialContent = initialContent
        self.initialHashtags = initialHashtags
        self.initialIsSensitive = initialIsSensitive
        self.initialAllowRelay = initialAllowRelay
        self.onSaved = onSaved
        self.onCancel = onCancel

        // Initialize state with initial values
        _title = State(initialValue: initialTitle)
        _content = State(initialValue: initialContent)
        _hashtags = State(initialValue: initialHashtags)
        _isSensitive = State(initialValue: initialIsSensitive)
        _allowRelay = State(initialValue: initialAllowRelay)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("post.edit_details".localized)) {
                    TextField("common.title".localized, text: $title)
                        .autocapitalization(.sentences)

                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if content.isEmpty {
                                    Text("drafts.description_placeholder".localized)
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
            .navigationTitle("post.edit_post".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        onCancel()
                    }
                    .disabled(isSubmitting)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized) {
                        savePost()
                    }
                    .disabled(title.isEmpty || isSubmitting)
                }
            }
            .disabled(isSubmitting)
            .overlay(
                Group {
                    if isSubmitting {
                        ProgressView("common.saving".localized)
                            .padding()
                            .background(Color(UIColor.systemBackground).opacity(0.9))
                            .cornerRadius(10)
                    }
                }
            )
        }
    }

    private func savePost() {
        guard !title.isEmpty else { return }

        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                try await service.editPost(
                    postId: postId,
                    title: title,
                    content: content,
                    hashtags: hashtags.isEmpty ? nil : hashtags,
                    isSensitive: isSensitive,
                    allowRelay: allowRelay
                )
                await MainActor.run {
                    onSaved()
                }
            } catch {
                await MainActor.run {
                    Logger.error("Failed to edit post", error: error, category: Logger.network)
                    errorMessage = "post.error_editing".localized
                    isSubmitting = false
                }
            }
        }
    }
}

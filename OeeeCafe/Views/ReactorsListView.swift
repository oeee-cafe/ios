import SwiftUI

struct ReactorsListView: View {
    let postId: String
    let emoji: String

    @State private var reactors: [Reactor] = []
    @State private var isLoading = false
    @State private var error: String?
    @Environment(\.dismiss) var dismiss

    private let postService = PostService.shared

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("common.loading".localized)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        Text("common.error".localized(error))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("common.retry".localized) {
                            Task {
                                await loadReactors()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if reactors.isEmpty {
                    VStack(spacing: 16) {
                        Text(emoji)
                            .font(.system(size: 48))
                        Text("reactions.no_reactions".localized)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(reactors) { reactor in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(reactor.actorName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Text(reactor.actorHandle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(emoji)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadReactors()
        }
    }

    private func loadReactors() async {
        isLoading = true
        error = nil

        do {
            let response = try await postService.fetchReactionsByEmoji(postId: postId, emoji: emoji)
            reactors = response.reactions
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

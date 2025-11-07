import SwiftUI

struct ProfileLinksSection: View {
    let links: [ProfileLink]

    var body: some View {
        if !links.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("profile.links".localized)
                    .font(.headline)
                    .padding(.horizontal)

                ForEach(links) { link in
                    Link(destination: URL(string: link.url)!) {
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 2) {
                                if let description = link.description {
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                                Text(link.url)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

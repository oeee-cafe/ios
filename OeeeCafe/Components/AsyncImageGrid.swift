import SwiftUI
import Kingfisher

/// Reusable async image grid item component
/// Consolidates PostGridItem, SearchPostGridItem, ProfilePostGridItem, CommunityDetailPostItem, etc.
struct AsyncImageGrid: View {
    let imageUrl: String
    let aspectRatio: CGFloat
    let applyBlur: Bool

    /// Standard square grid item
    init(imageUrl: String, applyBlur: Bool = false) {
        self.imageUrl = imageUrl
        self.aspectRatio = 1.0
        self.applyBlur = applyBlur
    }

    /// Grid item with custom aspect ratio
    init(imageUrl: String, aspectRatio: CGFloat, applyBlur: Bool = false) {
        self.imageUrl = imageUrl
        self.aspectRatio = aspectRatio
        self.applyBlur = applyBlur
    }

    var body: some View {
        GeometryReader { geometry in
            KFImage(URL(string: imageUrl))
                .placeholder {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            ProgressView()
                                .accessibilityHidden(true)
                        }
                }
                .onFailure { error in
                    // Error handling - Kingfisher will display placeholder
                    Logger.warning("Failed to load image: \(imageUrl)", category: Logger.app)
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .blur(radius: applyBlur ? 20 : 0)
                .clipped()
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .cornerRadius(Constants.CornerRadius.small)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Post image")
    }
}

#Preview("Square Grid Item") {
    AsyncImageGrid(imageUrl: "https://picsum.photos/300")
        .frame(width: 100, height: 100)
}

#Preview("Square Grid Item with Blur") {
    AsyncImageGrid(imageUrl: "https://picsum.photos/300", applyBlur: true)
        .frame(width: 100, height: 100)
}

#Preview("Wide Grid Item") {
    AsyncImageGrid(imageUrl: "https://picsum.photos/800/600", aspectRatio: 16/9)
        .frame(height: 200)
}

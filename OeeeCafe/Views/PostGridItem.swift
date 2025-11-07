import SwiftUI

struct PostGridItem: View {
    let post: Post

    var body: some View {
        AsyncImageGrid(imageUrl: post.imageUrl, applyBlur: post.isSensitive)
    }
}

import SwiftUI
import Kingfisher

struct ProfileBannerView: View {
    let imageUrl: String

    var body: some View {
        KFImage(URL(string: imageUrl))
            .placeholder {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay {
                        ProgressView()
                    }
            }
            .onFailure { error in
                // Error handling - Kingfisher will display placeholder
            }
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

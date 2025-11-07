import SwiftUI

/// Shared constants used throughout the app
enum Constants {
    /// API configuration
    enum API {
        // Deprecated: Use APIConfig.shared.baseURL instead for runtime-configurable URL
        // static let baseURL = "https://oeee.cafe"
    }

    /// Grid configuration for post grids (3 columns)
    static let postGridColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    /// Grid configuration for 2-column layouts (e.g., following grid)
    static let twoColumnGrid = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    /// Standard spacing values
    enum Spacing {
        static let grid: CGFloat = 8
        static let section: CGFloat = 12
        static let page: CGFloat = 24
        static let cardPadding: CGFloat = 16
    }

    /// Standard corner radius values
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }

    /// Standard image sizes
    enum ImageSize {
        static let thumbnail: CGFloat = 60
        static let avatar: CGFloat = 80
        static let banner: CGFloat = 100
    }
}

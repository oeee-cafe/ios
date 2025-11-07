import Foundation
import Kingfisher

class KingfisherConfig {
    static func configure() {
        let cache = ImageCache.default

        // Cache settings
        cache.memoryStorage.config.totalCostLimit = 300 * 1024 * 1024 // 300 MB memory cache
        cache.diskStorage.config.sizeLimit = 1000 * 1024 * 1024 // 1 GB disk cache
        cache.diskStorage.config.expiration = .days(365) // 1 year expiration

        // Downloader settings with exponential backoff retry
        let downloader = ImageDownloader.default
        downloader.downloadTimeout = 15.0

        // Configure retry with exponential backoff
        let retryStrategy = DelayRetryStrategy(maxRetryCount: 3, retryInterval: .accumulated(2))
        KingfisherManager.shared.defaultOptions = [
            .retryStrategy(retryStrategy),
            .transition(.fade(0.2)),
            .cacheOriginalImage
        ]
    }

    static func getCacheSize(completion: @escaping (UInt) -> Void) {
        ImageCache.default.calculateDiskStorageSize { result in
            switch result {
            case .success(let size):
                completion(size)
            case .failure:
                completion(0)
            }
        }
    }

    static func clearCache(completion: @escaping () -> Void) {
        ImageCache.default.clearMemoryCache()
        ImageCache.default.clearDiskCache {
            completion()
        }
    }
}

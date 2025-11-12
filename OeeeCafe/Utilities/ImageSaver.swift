import UIKit
import SwiftUI
import Combine
import Kingfisher
import Photos

@MainActor
class ImageSaver: ObservableObject {
    enum SaveResult {
        case success
        case failure(Error)
    }

    enum ImageSaveError: Error, LocalizedError {
        case downloadFailed
        case permissionDenied
        case saveFailed

        var errorDescription: String? {
            switch self {
            case .downloadFailed:
                return NSLocalizedString("post.image_download_failed", comment: "")
            case .permissionDenied:
                return NSLocalizedString("post.image_permission_denied", comment: "")
            case .saveFailed:
                return NSLocalizedString("post.image_save_failed", comment: "")
            }
        }
    }

    @Published var isSaving = false

    func saveImage(from url: String, completion: @escaping (SaveResult) -> Void) {
        guard let imageURL = URL(string: url) else {
            completion(.failure(ImageSaveError.downloadFailed))
            return
        }

        isSaving = true

        // First, retrieve the image using Kingfisher (from cache or download)
        KingfisherManager.shared.retrieveImage(with: imageURL) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let imageResult):
                    // Check photo library permission
                    let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

                    switch status {
                    case .authorized, .limited:
                        await self.saveToPhotoLibrary(image: imageResult.image, completion: completion)

                    case .notDetermined:
                        PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                            Task { @MainActor in
                                if newStatus == .authorized || newStatus == .limited {
                                    await self.saveToPhotoLibrary(image: imageResult.image, completion: completion)
                                } else {
                                    self.isSaving = false
                                    completion(.failure(ImageSaveError.permissionDenied))
                                }
                            }
                        }

                    case .denied, .restricted:
                        self.isSaving = false
                        completion(.failure(ImageSaveError.permissionDenied))

                    @unknown default:
                        self.isSaving = false
                        completion(.failure(ImageSaveError.permissionDenied))
                    }

                case .failure:
                    self.isSaving = false
                    completion(.failure(ImageSaveError.downloadFailed))
                }
            }
        }
    }

    private func saveToPhotoLibrary(image: UIImage, completion: @escaping (SaveResult) -> Void) async {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.creationRequestForAsset(from: image)
            }

            await MainActor.run {
                self.isSaving = false
                completion(.success)
            }
        } catch {
            await MainActor.run {
                self.isSaving = false
                completion(.failure(error))
            }
        }
    }
}

import Foundation
import Photos
import UIKit

class PhotosClient {
    func requestAuthorization() async -> LocalAssetAuthorizationStatus {
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    func getAssets(from: WithCursor<LocalAsset>) async -> WithCursor<LocalAsset> {
        return await withCheckedContinuation { continuation in
            let fetchOptions = PHFetchOptions()
            if let limit = from.limit {
                fetchOptions.fetchLimit = limit
            }
            if let cursor = from.cursor, let dateTime = cursor.dateTime {
                fetchOptions.predicate = NSPredicate(
                    format: "(mediaType == %d || mediaType == %d) and (creationDate < %@)",
                    PHAssetMediaType.image.rawValue,
                    PHAssetMediaType.video.rawValue,
                    dateTime as NSDate
                )
            } else {
                fetchOptions.predicate = NSPredicate(
                    format: "(mediaType == %d || mediaType == %d)",
                    PHAssetMediaType.image.rawValue,
                    PHAssetMediaType.video.rawValue
                )
            }
            fetchOptions.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending: false)
            ]

            var assets: [PHAsset] = []
            PHAsset.fetchAssets(with: fetchOptions).enumerateObjects { asset, _, _ in
                assets.append(asset)
            }

            let nextPager = from.next(
                assets,
                cursor: assets.last?.creationDate?.dateTimeString,
                hasNext: assets.count > 0
            )

            continuation.resume(returning: nextPager)
        }
    }

    func getAssets() async -> [LocalAsset] {
        return await withCheckedContinuation { continuation in
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(
                format: "(mediaType == %d || mediaType == %d)",
                argumentArray: [
                    PHAssetMediaType.image.rawValue,
                    PHAssetMediaType.video.rawValue
                ]
            )
            fetchOptions.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending: false)
            ]

            var assets: [PHAsset] = []
            PHAsset.fetchAssets(with: fetchOptions).enumerateObjects { asset, _, _ in
                assets.append(asset)
            }

            continuation.resume(returning: assets)
        }
    }

    func getAsset(id: String) async throws -> LocalAsset {
        return try await withCheckedThrowingContinuation { continuation in
            var assets: [PHAsset] = []
            PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).enumerateObjects { asset, _, _ in
                assets.append(asset)
            }

            guard let asset = assets.first else {
                continuation.resume(throwing: AppError.plain("error"))
                return
            }

            continuation.resume(returning: asset)
        }
    }

    func requestImage(asset: PHAsset, targetSize: CGSize) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                guard let image = image else {
                    continuation.resume(throwing: AppError.plain("error"))
                    return
                }

                continuation.resume(returning: image)
            }
        }
    }

    func requestCachedImage(
        asset: PHAsset,
        targetSize: CGSize,
        completion: @escaping (UIImage?) -> ()
    ) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic

        return PHCachingImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options,
            resultHandler: { image, _ in
                completion(image)
            }
        )
    }

    func requestFullImage(asset: PHAsset) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                guard let image = image else {
                    continuation.resume(throwing: AppError.plain("error"))
                    return
                }

                continuation.resume(returning: image)
            }
        }
    }

    func requestImageData(asset: PHAsset) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            PHImageManager.default().requestImageDataAndOrientation(
                for: asset,
                options: options
            ) { data, _, _, _ in
                guard let data = data else {
                    continuation.resume(throwing: AppError.plain("error"))
                    return
                }

                continuation.resume(returning: data)
            }
        }
    }

    func requestFullVideo(asset: PHAsset) async throws -> AVAsset {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestAVAsset(
                forVideo: asset,
                options: options
            ) { avAsset, _, _ in
                guard let avAsset = avAsset else {
                    continuation.resume(throwing: AppError.plain("error"))
                    return
                }

                continuation.resume(returning: avAsset)
            }
        }
    }

    func requestVideoData(asset: PHAsset) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true

            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                guard let avAsset = avAsset else {
                    continuation.resume(throwing: AppError.plain("error"))
                    return
                }

                guard let urlAsset = avAsset as? AVURLAsset else {
                    continuation.resume(throwing: AppError.plain("error"))
                    return
                }

                do {
                    let data = try Data(contentsOf: urlAsset.url)
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

typealias LocalAssetAuthorizationStatus = PHAuthorizationStatus

extension String {
    var dateTime: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.date(from: self)
    }
}

extension Date {
    var dateTimeString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: self)
    }
}

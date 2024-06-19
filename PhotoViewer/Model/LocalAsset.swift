import Foundation
import Photos

typealias LocalAsset = PHAsset
extension LocalAsset: Identifiable {
    public var id: String {
        return localIdentifier
    }

    var isVideo: Bool {
        return mediaType == .video
    }

    var videoDurationSecond: Int? {
        if self.isVideo {
            return Int(round(duration))
        } else {
            return nil
        }
    }

    var displayDurationSecond: String {
        guard let second = videoDurationSecond else {
            return ""
        }
        return "\(second)S"
    }
}

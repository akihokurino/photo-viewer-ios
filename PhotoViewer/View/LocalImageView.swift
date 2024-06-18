import Photos
import SwiftUI

struct LocalImageView: View {
    private let asset: LocalAsset
    private let size: CGSize
    private var isCircle: Bool = false
    private let radius: CGFloat
    
    @ObservedObject var resolver: LocalImageResolver
    
    init(asset: LocalAsset, size: CGSize, isCircle: Bool = false, radius: CGFloat = 0) {
        self.resolver = LocalImageResolver(asset: asset, size: size)
        self.asset = asset
        self.size = size
        self.isCircle = isCircle
        self.radius = radius
    }
        
    var body: some View {
        ZStack {
            if let image = resolver.displayImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .cornerRadius(radius)
                    .applySize(size: size)
                    .applyClip(isCircle: isCircle)
                    .cornerRadius(radius)
                    .contentShape(RoundedRectangle(cornerRadius: radius))
            } else {
                ProgressView()
                    .applySize(size: size)
            }
            
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    Text(asset.displayDurationSecond)
                        .font(.caption)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                    Spacer4()
                }
                Spacer4()
            }
        }
        .onDisappear {
            resolver.clean()
        }
    }
}

class LocalImageResolver: ObservableObject {
    private let asset: LocalAsset
    private let size: CGSize
    private var requestID: PHImageRequestID?
    
    @Published var displayImage: UIImage?
    
    init(asset: LocalAsset, size: CGSize) {
        self.asset = asset
        self.size = size
        if !imageFromCache() {
            imageFromLocalDevice()
        }
    }
    
    func imageFromCache() -> Bool {
        guard let cacheImage = DiskCachedImageStore.shared.get(key: asset.id) else { return false }
        displayImage = cacheImage
        return true
    }
    
    func imageFromLocalDevice() {
        requestID = PhotosClient.liveValue.requestCachedImage(
            asset: asset,
            targetSize: CGSize(width: size.width * 2, height: size.height * 2),
            completion: { image in
                guard let image = image else {
                    return
                }
                
                DiskCachedImageStore.shared.set(key: self.asset.id, image: image)
                DispatchQueue.main.async {
                    self.displayImage = image
                }
            })
    }
    
    func clean() {
        if let requestID = requestID {
            PHCachingImageManager.default().cancelImageRequest(requestID)
        }
    }
}

extension View {
    func applySize(size: CGSize?) -> some View {
        Group {
            if let size = size {
                self.frame(width: size.width, height: size.height)
            } else {
                self.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    func applyClip(isCircle: Bool) -> some View {
        Group {
            if isCircle {
                self.clipShape(Circle())
            } else {
                self.clipped()
            }
        }
    }
}

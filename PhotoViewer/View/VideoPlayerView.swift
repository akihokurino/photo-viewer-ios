import AVKit
import SwiftUI

struct LoopVideoPlayerView: View {
    private let asset: LocalAsset
    private let size: CGSize
    private let start: Double
    private let end: Double?
    private let namespace: Namespace.ID?
    private let suppressLoop: Bool
    @StateObject var resolver: VideoResolver
    @State private var player = AVPlayer()
    @State private var timeObserverToken: Any?
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0

    init(asset: LocalAsset,
         size: CGSize,
         start: Double = 0,
         end: Double? = nil,
         namespace: Namespace.ID? = nil,
         suppressLoop: Bool = false)
    {
        self._resolver = StateObject(wrappedValue: VideoResolver(asset: asset))
        self.asset = asset
        self.size = size
        self.start = start
        self.end = end
        self.namespace = namespace
        self.suppressLoop = suppressLoop
    }

    var body: some View {
        ZStack {
            if let avasset = resolver.displayAVAsset {
                AVPlayerView(player: player)
                    .applyGeometryEffect(id: asset.id, namespace: namespace, isSource: true)
                    .applySize(size: size, autoHeight: true)
                    .onAppear {
                        start(video: AVPlayerItem(asset: avasset))
                    }
                    .onDisappear {
                        cleanUp()
                    }
            } else {
                ProgressView()
                    .applySize(size: size)
            }

            VStack {
                Spacer16()
                HStack {
                    Spacer16()
                    HStack {
                        Text("00:\(String(format: "%02d", Int(currentTime)))")
                            .font(.footnote)
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 12)
                    .background(RoundedRectangle(cornerRadius: .infinity).fill(.regularMaterial))
                    .foregroundColor(.white)
                    Spacer()
                }

                Spacer()
            }
        }
    }

    private func start(video: AVPlayerItem) {
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}

        player.replaceCurrentItem(with: video)
        player.seek(to: CMTime(seconds: start, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        player.play()

        Task {
            do {
                let _duration = try await player.currentItem?.asset.load(.duration)
                DispatchQueue.main.async {
                    self.duration = _duration?.seconds ?? 0.0
                }
            } catch {}
        }

        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            if let end = end, time.seconds >= end {
                let seekTime = CMTime(seconds: self.start, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                self.player.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                    if !suppressLoop {
                        self.player.play()
                    }
                }
            }

            currentTime = time.seconds
        }

        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            let seekTime = CMTime(seconds: self.start, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            self.player.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                if !suppressLoop {
                    self.player.play()
                }
            }
        }
    }

    private func cleanUp() {
        player.pause()

        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
    }
}

class PlayerUIView: UIView {
    var playerLayer: AVPlayerLayer

    init(player: AVPlayer) {
        self.playerLayer = AVPlayerLayer(player: player)
        super.init(frame: .zero)
        layer.addSublayer(playerLayer)
        playerLayer.videoGravity = .resizeAspect
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

struct AVPlayerView: UIViewRepresentable {
    var player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        return PlayerUIView(player: player)
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {}
}

class VideoResolver: ObservableObject {
    private let asset: LocalAsset

    @Published var displayAVAsset: AVAsset?

    init(asset: LocalAsset) {
        self.asset = asset

        if !localVideoFromCache() {
            localVideoFromLocalDevice()
        }
    }

    func localVideoFromCache() -> Bool {
        guard let cacheAVAsset = CachedVideoStore.shared.get(key: asset.id) else { return false }
        displayAVAsset = cacheAVAsset
        return true
    }

    func localVideoFromLocalDevice() {
        Task {
            do {
                let avAsset = try await PhotosClient.liveValue.requestFullVideo(asset: asset)
                CachedVideoStore.shared.set(key: asset.id, video: avAsset)
                DispatchQueue.main.async {
                    self.displayAVAsset = avAsset
                }
            } catch {}
        }
    }
}

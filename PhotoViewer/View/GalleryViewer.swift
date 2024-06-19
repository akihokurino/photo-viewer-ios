import SwiftUI

struct GalleryViewer: View {
    let namespace: Namespace.ID
    let items: [LocalAsset]
    let size: CGSize
    let onChangeIndex: (_ index: Int) -> Void
    let onClose: () -> Void
    let hStackSpacing: CGFloat = 2

    @State private var index: Int
    @State private var pagerOffsetSize: CGSize
    @State private var imageOffsetSize: CGSize
    @State private var dragStartAxis: DragAxis?
    @State private var currentScale: CGFloat = 1.0
    @State private var previousScale: CGFloat = 1.0
    @State private var previousTranslation = CGSize.zero

    enum DragAxis {
        case horizontal
        case verticalUp
        case verticalDown
    }

    var isDissmissDragging: Bool {
        abs(imageOffsetSize.width) > 0 || abs(imageOffsetSize.height) > 0
    }

    var selectedItem: LocalAsset? {
        guard !items.isEmpty && items.count > index else {
            return nil
        }
        return items[index]
    }

    init(namespace: Namespace.ID, items: [LocalAsset], index: Int, size: CGSize, onChangeIndex: @escaping (_ index: Int) -> Void, onClose: @escaping () -> Void) {
        self.namespace = namespace
        self.items = items
        self.size = size
        self.onChangeIndex = onChangeIndex
        self.onClose = onClose

        self.index = index
        self.pagerOffsetSize = CGSize(width: -(size.width + hStackSpacing) * CGFloat(index), height: 0)
        self.imageOffsetSize = .zero
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .opacity(
                    currentScale < 1 ? currentScale : 1.0 - (imageOffsetSize.height / size.height)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            LazyHStack(spacing: hStackSpacing) {
                ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                    if item == selectedItem {
                        LocalImageView(asset: item, size: size, namespace: namespace, autoHeight: true)
                            .offset(imageOffsetSize)
                            .scaleEffect(currentScale)
                    } else if abs(i - index) <= 5 {
                        LocalImageView(asset: item, size: size, autoHeight: true)
                    } else {
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(width: size.width, height: size.height)
                    }
                }
            }
            .frame(width: (size.width + hStackSpacing) * CGFloat(items.count) - hStackSpacing, height: size.height)
            .offset(pagerOffsetSize)
            .gesture(dragGesture)
            .simultaneousGesture(panGesture)
        }
    }

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 50, coordinateSpace: .global)
            .onChanged { value in
                if currentScale > 1 {
                    let width = min(150, max(-150, previousTranslation.width + value.translation.width / currentScale))
                    let height = min(250, max(-250, previousTranslation.height + value.translation.height / currentScale))
                    imageOffsetSize = CGSize(width: width, height: height)
                    return
                }

                switch dragStartAxis {
                case .horizontal:
                    if value.translation.width > 0 && index == 0 {
                        pagerOffsetSize.width = -(size.width + hStackSpacing) * CGFloat(index) + value.translation.width * 0.3
                    } else if value.translation.width < 0 && index == items.count - 1 {
                        pagerOffsetSize.width = -(size.width + hStackSpacing) * CGFloat(index) + value.translation.width * 0.3
                    } else {
                        pagerOffsetSize.width = -(size.width + hStackSpacing) * CGFloat(index) + value.translation.width * 0.6
                    }
                case .verticalUp:
                    break
                case .verticalDown:
                    imageOffsetSize = value.translation
                case nil:
                    if abs(value.predictedEndTranslation.width) > abs(value.predictedEndTranslation.height) {
                        dragStartAxis = .horizontal
                    } else {
                        dragStartAxis = value.translation.height > 0 ? .verticalDown : .verticalUp
                    }
                }
            }
            .onEnded { value in
                if currentScale > 1 {
                    previousTranslation = imageOffsetSize
                    return
                }

                switch dragStartAxis {
                case .horizontal:
                    var targetIndex = index
                    if value.predictedEndTranslation.width < -size.width / 2 && index + 1 < items.count {
                        targetIndex += 1
                    } else if value.predictedEndTranslation.width > size.width / 2 && index > 0 {
                        targetIndex -= 1
                    }
                    withAnimation(.easeOut(duration: 0.2)) {
                        pagerOffsetSize = CGSize(width: -(size.width + hStackSpacing) * CGFloat(targetIndex), height: 0)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                        index = targetIndex
                        onChangeIndex(targetIndex)
                    }
                case .verticalUp:
                    break
                case .verticalDown:
                    if value.translation.height > 0 {
                        onClose()
                    } else {
                        withAnimation(.easeOut(duration: 0.2)) {
                            imageOffsetSize = .zero
                        }
                    }
                case nil:
                    break
                }
                dragStartAxis = nil
            }
    }

    var panGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / previousScale
                previousScale = value
                let nextScale = min(max(currentScale * delta, 0.3), 3)
                currentScale = nextScale
            }
            .onEnded { _ in
                previousScale = 1.0
                if currentScale < 0.8 {
                    onClose()
                } else if currentScale < 1.5 {
                    previousTranslation = .zero
                    withAnimation(.easeOut(duration: 0.2)) {
                        currentScale = 1
                        imageOffsetSize = .zero
                    }
                }
            }
    }
}

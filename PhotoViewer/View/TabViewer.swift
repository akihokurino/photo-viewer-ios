import SwiftUI

struct TabViewer: View {
    let namespace: Namespace.ID
    let items: [LocalAsset]
    let size: CGSize
    let onChangeIndex: (_ index: Int) -> Void

    @State private var index: Int

    init(namespace: Namespace.ID, items: [LocalAsset], size: CGSize, index: Int, onChangeIndex: @escaping (_ index: Int) -> Void) {
        self.namespace = namespace
        self.items = items
        self.size = size
        self.index = index
        self.onChangeIndex = onChangeIndex
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            TabView(selection: $index) {
                ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                    GeometryReader { g in
                        Group {
                            ZoomableScrollView {
                                LocalImageView(asset: item, size: size, autoHeight: true)
                            }
                        }
                        .position(x: g.frame(in: .local).midX, y: g.frame(in: .local).midY)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(i)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .onChange(of: index) { _, new in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                onChangeIndex(new)
            }
        }
    }
}

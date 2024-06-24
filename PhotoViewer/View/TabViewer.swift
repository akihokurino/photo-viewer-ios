import SwiftUI

struct TabViewer: View {
    let namespace: Namespace.ID
    let items: [LocalAsset]
    let size: CGSize

    @Binding var index: Int

    init(namespace: Namespace.ID, items: [LocalAsset], size: CGSize, index: Binding<Int>) {
        self.namespace = namespace
        self.items = items
        self.size = size

        self._index = index
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
    }
}

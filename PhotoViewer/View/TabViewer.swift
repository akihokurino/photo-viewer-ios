import SwiftUI

struct TabViewer: View {
    let namespace: Namespace.ID
    let items: [LocalAsset]
    let size: CGSize
    let controlingToolbars: [ToolbarPlacement]
    let onChangeIndex: (_ index: Int) -> Void
    let onClose: () -> Void

    @State private var index: Int
    @State private var isFullscreen = false

    init(namespace: Namespace.ID,
         items: [LocalAsset],
         size: CGSize,
         index: Int,
         controlingToolbars: [ToolbarPlacement] = [],
         onChangeIndex: @escaping (_ index: Int) -> Void,
         onClose: @escaping () -> Void)
    {
        self.namespace = namespace
        self.items = items
        self.size = size
        self.index = index
        self.controlingToolbars = controlingToolbars
        self.onChangeIndex = onChangeIndex
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            ZStack {
                Color(UIColor.systemBackground)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()

                TabView(selection: $index) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                        if item.isVideo {
                            LoopVideoPlayerView(asset: item, size: size, suppressLoop: true)
                                .ignoresSafeArea()
                                .tag(i)
                        } else {
                            GeometryReader { g in
                                Group {
                                    ZoomableScrollView {
                                        LocalImageView(asset: item, size: size, autoHeight: true)
                                    }
                                }
                                .position(x: g.frame(in: .local).midX, y: g.frame(in: .local).midY)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .ignoresSafeArea()
                            .tag(i)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .gesture(tapGesture)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()

            ForEach(controlingToolbars) {
                if !isFullscreen {
                    if $0.id == ToolbarPlacement.navigationBar.id {
                        Color.clear
                            .toolbarBackground(.visible, for: .navigationBar)
                    } else if $0.id == ToolbarPlacement.tabBar.id {
                        Color.clear
                            .toolbarBackground(.visible, for: .tabBar)
                    }
                }

                Color.clear
                    .toolbar(isFullscreen ? .hidden : .visible, for: $0)
            }
        }
        .statusBar(hidden: isFullscreen)
        .navigationBarItems(leading: Group {
            Button(action: {
                onChangeIndex(index)
                onClose()
            }) {
                Image(systemName: "xmark").foregroundColor(Color(UIColor.label))
            }
        })
    }

    var tapGesture: some Gesture {
        TapGesture(count: 1)
            .onEnded {
                withAnimation(.easeOut(duration: 0.2)) {
                    isFullscreen.toggle()
                }
            }
    }
}

extension ToolbarPlacement: Identifiable {
    public var id: String {
        "\(self)"
    }
}

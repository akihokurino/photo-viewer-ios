import ComposableArchitecture
import SwiftUI

struct ContentView: View {
    let store: StoreOf<AppReducer>

    @Namespace private var namespace
    @State private var isPresentedGalleryViewer: Bool = false

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                GeometryReader { geometry in
                    ScrollViewReader { reader in
                        ZStack {
                            PagingGridView(columns: 3, gap: 2, size: geometry.size, itemView: { index, asset in
                                let size = CGSize(
                                    width: (geometry.size.width - 4) / 3,
                                    height: (geometry.size.width - 4) / 3
                                )

                                if index != viewStore.assetSelection {
                                    return AnyView(LocalImageView(
                                        asset: asset,
                                        size: size,
                                        namespace: namespace
                                    ))
                                } else {
                                    return AnyView(Rectangle()
                                        .foregroundColor(.clear)
                                        .frame(width: size.width, height: size.height)
                                    )
                                }
                            }, onTap: { index, _ in
                                withAnimation(.easeOutExpo) {
                                    isPresentedGalleryViewer = true
                                }
                                viewStore.send(.setAssetSelection(index))
                            }, onNext: {
                                viewStore.send(.nextLocalAssets)
                            }, onRefresh: {
                                viewStore.send(.refreshLocalAssets)
                            }, data: viewStore.binding(
                                get: { _ in viewStore.assets },
                                send: { AppReducer.Action.setAssets($0) }
                            ), isLoading: viewStore.binding(
                                get: { $0.isPresentedNextLoading },
                                send: AppReducer.Action.isPresentedNextLoading
                            ), isRefreshing: viewStore.binding(
                                get: { $0.isPresentedPullToRefresh },
                                send: AppReducer.Action.isPresentedPullToRefresh
                            ))
                            .zIndex(1)

                            if isPresentedGalleryViewer {
                                GeometryReader(content: { proxy in
                                    GalleryViewer(namespace: namespace, items: viewStore.assets.items, index: viewStore.assetSelection ?? 0, size: proxy.size, onChangeIndex: { index in
                                        reader.scrollTo(viewStore.assets.items[index].id)
                                        viewStore.send(.setAssetSelection(index))
                                    }) {
                                        withAnimation(.easeOutExpo) {
                                            isPresentedGalleryViewer = false
                                        }
                                        viewStore.send(.setAssetSelection(nil))
                                    }
                                })
                                .zIndex(2)
                            }
                        }
                        .onAppear {
                            viewStore.send(.initialize)
                        }
                        .navigationTitle(viewStore.navigationTitle)
                        .navigationBarTitleDisplayMode(.inline)
                        .modifier(HUDModifier(isPresented: viewStore.binding(
                            get: { $0.isPresentedHUD },
                            send: AppReducer.Action.isPresentedHUD
                        )))
                    }
                }
            }
        }
    }
}

extension Animation {
    static let easeOutExpo: Animation = .timingCurve(0.25, 0.8, 0.1, 1, duration: 0.5)
}

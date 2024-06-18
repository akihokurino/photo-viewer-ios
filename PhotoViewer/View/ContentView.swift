import ComposableArchitecture
import SwiftUI

struct ContentView: View {
    let store: StoreOf<AppReducer>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                GeometryReader { geometry in
                    VStack {
                        ScrollView {
                            LazyVStack {
                                ForEach(DateGroup<LocalAsset>.from(assets: viewStore.localAssets.items), id: \.id) { group in
                                    VStack(alignment: .leading) {
                                        Spacer20()
                                        
                                        HStack {
                                            Text(group.date.dateString)
                                                .font(.title3)
                                                .foregroundColor(Color(UIColor.secondaryLabel))
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .frame(height: 32)
                                        
                                        Spacer12()
                                        
                                        LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 2), count: 3), spacing: 2) {
                                            ForEach(group.assets, id: \.self) { asset in
                                                Button(action: {}) {
                                                    LocalImageView(
                                                        asset: asset,
                                                        size: CGSize(
                                                            width: (geometry.size.width - 4) / 3,
                                                            height: (geometry.size.width - 4) / 3
                                                        )
                                                    )
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .refreshable {
                            guard viewStore.isPresentedPullToRefresh else {
                                return
                            }
                            viewStore.send(.refreshLocalAssets)
                        }
                        
//                        PagingGridView(columns: 3, gap: 4, itemView: { asset in
//                            AnyView(
//                                LocalImageView(
//                                    asset: asset,
//                                    size: CGSize(
//                                        width: (geometry.size.width - 4) / 3,
//                                        height: (geometry.size.width - 4) / 3
//                                    )
//                                )
//                            )
//                        }, onTap: { _ in }, onNext: {
//                            viewStore.send(.nextLocalAssets)
//                        }, onRefresh: {
//                            viewStore.send(.refreshLocalAssets)
//                        }, data: viewStore.binding(
//                            get: { _ in viewStore.localAssets },
//                            send: { AppReducer.Action.setLocalAssets($0) }
//                        ), isLoading: viewStore.binding(
//                            get: { $0.isPresentedNextLoading },
//                            send: AppReducer.Action.isPresentedNextLoading
//                        ), isRefreshing: viewStore.binding(
//                            get: { $0.isPresentedPullToRefresh },
//                            send: AppReducer.Action.isPresentedPullToRefresh
//                        ))
                    }
                    .onAppear {
                        viewStore.send(.initialize)
                    }
                    .navigationTitle("Photos")
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

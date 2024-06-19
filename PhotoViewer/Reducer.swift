import ComposableArchitecture
import Foundation

extension PhotosClient: DependencyKey {
    static let liveValue = PhotosClient()
}

extension DependencyValues {
    var photosClient: PhotosClient {
        get { self[PhotosClient.self] }
        set { self[PhotosClient.self] = newValue }
    }
}

let limit = 30

struct AppReducer: Reducer {
    @Dependency(\.photosClient) var photosClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .initialize:
                guard !state.initialized else {
                    return .none
                }

                state.initialized = true
                state.isPresentedHUD = true
                let pager = state.assets

                return .run { send in
                    let status = await photosClient.requestAuthorization()

                    if status == .authorized || status == .limited {
                        let result = await photosClient.getAssets(from: pager)
                        await send(.setAssets(result))
                    }

                    await send(.isPresentedHUD(false))
                }
            case .nextLocalAssets:
                guard !state.isPresentedNextLoading else {
                    return .none
                }

                state.isPresentedNextLoading = true
                let pager = state.assets

                return .run { send in
                    let nextPager = await photosClient.getAssets(from: pager)
                    await send(.setAssets(nextPager))
                    await send(.isPresentedNextLoading(false))
                }
            case .refreshLocalAssets:
                guard !state.isPresentedPullToRefresh else {
                    return .none
                }

                state.isPresentedPullToRefresh = true
                let pager = WithCursor<LocalAsset>.new(limit: limit)

                return .run { send in
                    let nextPager = await photosClient.getAssets(from: pager)
                    await send(.setAssets(nextPager))
                    await send(.isPresentedPullToRefresh(false))
                }
            case .setAssets(let assets):
                state.assets = assets
                return .none
            case .setAssetSelection(let val):
                state.assetSelection = val
                return .none
            case .isPresentedHUD(let val):
                state.isPresentedHUD = val
                return .none
            case .isPresentedNextLoading(let val):
                state.isPresentedNextLoading = val
                return .none
            case .isPresentedPullToRefresh(let val):
                state.isPresentedPullToRefresh = val
                return .none
            }
        }
    }
}

extension AppReducer {
    struct State: Equatable {
        var initialized = false
        var assets: WithCursor<LocalAsset> = WithCursor.new()
        var assetSelection: Int?
        var isPresentedHUD = false
        var isPresentedNextLoading = false
        var isPresentedPullToRefresh = false

        var navigationTitle: String {
            if let selection = assetSelection {
                return "Photos - \(selection)"
            } else {
                return "Photos"
            }
        }
    }

    enum Action {
        case initialize
        case nextLocalAssets
        case refreshLocalAssets
        case setAssets(WithCursor<LocalAsset>)
        case setAssetSelection(Int?)
        case isPresentedHUD(Bool)
        case isPresentedNextLoading(Bool)
        case isPresentedPullToRefresh(Bool)
    }
}

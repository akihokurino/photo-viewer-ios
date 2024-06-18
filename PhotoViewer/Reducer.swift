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

                return .run { send in
                    let status = await photosClient.requestAuthorization()

                    if status == .authorized || status == .limited {
                        let result = await photosClient.getAssets(from: WithCursor<LocalAsset>.new())
                        await send(.setLocalAssets(result))
                    }

                    await send(.isPresentedHUD(false))
                }
            case .nextLocalAssets:
                guard !state.isPresentedNextLoading else {
                    return .none
                }

                state.isPresentedNextLoading = true
                let pager = state.localAssets

                return .run { send in
                    let nextPager = await photosClient.getAssets(from: pager)
                    await send(.setLocalAssets(nextPager))

                    await send(.isPresentedNextLoading(false))
                }
            case .refreshLocalAssets:
                state.isPresentedPullToRefresh = true

                return .run { send in
                    let nextPager = await photosClient.getAssets(from: WithCursor<LocalAsset>.new())
                    await send(.setLocalAssets(nextPager))

                    await send(.isPresentedPullToRefresh(false))
                }
            case .setLocalAssets(let assets):
                state.localAssets = assets
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
        var localAssets: WithCursor<LocalAsset> = WithCursor.new()
        var isPresentedHUD = false
        var isPresentedNextLoading = false
        var isPresentedPullToRefresh = false
    }

    enum Action {
        case initialize
        case nextLocalAssets
        case refreshLocalAssets
        case setLocalAssets(WithCursor<LocalAsset>)
        case isPresentedHUD(Bool)
        case isPresentedNextLoading(Bool)
        case isPresentedPullToRefresh(Bool)
    }
}

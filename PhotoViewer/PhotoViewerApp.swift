import ComposableArchitecture
import SwiftUI

@main
struct PhotoViewerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(store: Store(initialState: AppReducer.State()) {
                AppReducer()
            })
        }
    }
}

enum AppError: Error {
    case plain(String)
}

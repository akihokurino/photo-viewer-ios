import SwiftUI

struct HUD: View {
    @Binding var isLoading: Bool

    var body: some View {
        ZStack {
            if isLoading {
                Group {
                    ProgressView()
                        .frame(width: 50, height: 50, alignment: .center)
                }
                .frame(width: 100, height: 100, alignment: .center)
                .background(Color.gray.opacity(0.5))
                .cornerRadius(5.0)
            }
        }
        .frame(minWidth: 0,
               maxWidth: .infinity,
               minHeight: 0,
               maxHeight: .infinity,
               alignment: .center)
        .edgesIgnoringSafeArea(.all)
    }
}

struct HUDModifier: ViewModifier {
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    HUD(isLoading: $isPresented)
                }, alignment: .center
            )
    }
}

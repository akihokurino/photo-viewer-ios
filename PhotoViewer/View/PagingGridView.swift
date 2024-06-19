import SwiftUI

struct PagingGridView<T: Identifiable>: View {
    let space = "PagingGridView"
    let columns: Int
    let gap: CGFloat
    let size: CGSize
    let itemView: (Int, T) -> AnyView
    let onTap: (Int, T) -> Void
    let onNext: () -> Void
    let onRefresh: () async -> Void

    @Binding var data: WithCursor<T>
    @Binding var isLoading: Bool
    @Binding var isRefreshing: Bool

    @State private var scrollOffset: CGFloat = .zero

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: gap), count: columns) as [GridItem], spacing: gap) {
                        ForEach(Array(data.items.enumerated()), id: \.element.id) { index, item in
                            itemView(index, item).onTapGesture {
                                onTap(index, item)
                            }
                        }
                    }

                    GeometryReader { geometry in
                        Color.clear.preference(key: PagingGridViewOffsetKey.self, value: geometry.frame(in: .named(space)).maxY)
                    }
                }

                if isLoading && data.hasNext {
                    indicator
                }
            }
        }
        .coordinateSpace(name: space)
        .onPreferenceChange(PagingGridViewOffsetKey.self) { offset in
            if !isLoading && !isRefreshing && offset < size.height + 1 && data.items.count > 0 && data.hasNext {
                onNext()
            }
        }
        .refreshable {
            guard !isLoading && !isRefreshing else {
                return
            }
            await onRefresh()
        }
    }

    var indicator: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
    }
}

struct PagingGridViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

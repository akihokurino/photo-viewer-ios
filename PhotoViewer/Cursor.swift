import Foundation

import Foundation

struct WithCursor<T: Identifiable>: Equatable {
    let items: [T]
    let cursor: String?
    let hasNext: Bool
    let limit: Int?
    
    func next(_ nextItems: [T], cursor: String?, hasNext: Bool) -> WithCursor {
        var _next = items
        _next.append(contentsOf: nextItems)
        return WithCursor(items: _next, cursor: cursor, hasNext: hasNext, limit: limit)
    }
    
    static func new(limit: Int? = nil) -> WithCursor {
        return WithCursor(items: [], cursor: nil, hasNext: false, limit: limit)
    }
    
    static func == (lhs: WithCursor<T>, rhs: WithCursor<T>) -> Bool {
        guard lhs.cursor == rhs.cursor else { return false }
        guard lhs.items.count == rhs.items.count else { return false }
                    
        for (leftItem, rightItem) in zip(lhs.items, rhs.items) {
            guard leftItem.id == rightItem.id else { return false }
        }
                    
        return true
    }
}

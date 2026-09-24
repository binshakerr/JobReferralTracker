import Foundation

enum LoadState<Value> {
    case loading
    case loaded(Value)
    case failed(message: String)

    var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }
}

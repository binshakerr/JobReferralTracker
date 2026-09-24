import Foundation

/// Emits an event every time the persistent store saves changes.
protocol DataChangeObserving: Sendable {
    func changes() -> AsyncStream<Void>
}

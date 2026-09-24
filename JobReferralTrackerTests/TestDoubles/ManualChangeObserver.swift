import Foundation
@testable import JobReferralTracker

/// Change notifications triggered by the test (or by `InMemoryRepository` writes).
final class ManualChangeObserver: DataChangeObserving, @unchecked Sendable {
    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    var subscriberCount: Int {
        lock.withLock { continuations.count }
    }

    func changes() -> AsyncStream<Void> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let id = UUID()
            lock.withLock { continuations[id] = continuation }
            continuation.onTermination = { [weak self] _ in
                self?.lock.withLock { _ = self?.continuations.removeValue(forKey: id) }
            }
        }
    }

    func send() {
        let current = lock.withLock { Array(continuations.values) }
        current.forEach { $0.yield() }
    }
}

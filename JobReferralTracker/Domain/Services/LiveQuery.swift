import Foundation

/// Turns a one-shot fetch into a live stream that re-fetches after every store change.
struct LiveQuery: Sendable {
    let changeObserver: DataChangeObserving

    func stream<Value: Sendable>(
        _ fetch: @escaping @Sendable () async throws -> Value
    ) -> AsyncThrowingStream<Value, Error> {
        AsyncThrowingStream { continuation in
            // Subscribe before the first fetch so a change between the two is not missed.
            let changes = changeObserver.changes()
            let task = Task {
                do {
                    continuation.yield(try await fetch())
                    for await _ in changes {
                        try Task.checkCancellation()
                        continuation.yield(try await fetch())
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

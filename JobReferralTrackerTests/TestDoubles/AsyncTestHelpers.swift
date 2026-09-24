import XCTest
@testable import JobReferralTracker

/// Polls `condition` until it is true, failing the test after `timeout`.
@MainActor
func waitUntil(
    timeout: TimeInterval = 2,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ condition: () -> Bool
) async {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        if Date() > deadline {
            XCTFail("Condition not met within \(timeout)s", file: file, line: line)
            return
        }
        try? await Task.sleep(nanoseconds: 10_000_000)
    }
}

/// Thread-safe counter for use inside `@Sendable` closures.
final class LockedCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int { lock.withLock { count } }

    @discardableResult
    func increment() -> Int {
        lock.withLock {
            count += 1
            return count
        }
    }
}

/// Controllable current time.
final class TestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date

    init(_ date: Date) { current = date }

    var now: Date {
        get { lock.withLock { current } }
        set { lock.withLock { current = newValue } }
    }
}

enum TestStack {
    /// A loaded, empty in-memory Core Data stack.
    static func make() async throws -> CoreDataStack {
        let stack = CoreDataStack(storeType: .inMemory)
        try await stack.load()
        return stack
    }
}

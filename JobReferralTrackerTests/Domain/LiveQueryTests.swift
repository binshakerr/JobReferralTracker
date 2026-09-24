import XCTest
@testable import JobReferralTracker

@MainActor
final class LiveQueryTests: XCTestCase {
    func testYieldsInitialValueThenRefetchesAfterEachChange() async throws {
        let changes = ManualChangeObserver()
        let fetches = LockedCounter()
        var iterator = LiveQuery(changeObserver: changes).stream { fetches.increment() }.makeAsyncIterator()

        let first = try await iterator.next()
        changes.send()
        let second = try await iterator.next()
        changes.send()
        let third = try await iterator.next()

        XCTAssertEqual([first, second, third], [1, 2, 3])
    }

    func testChangeBetweenSubscribeAndFirstFetchIsNotMissed() async throws {
        let changes = ManualChangeObserver()
        let fetches = LockedCounter()
        let stream = LiveQuery(changeObserver: changes).stream { fetches.increment() }
        changes.send() // Before anyone iterates.
        var iterator = stream.makeAsyncIterator()

        let first = try await iterator.next()
        let second = try await iterator.next()

        XCTAssertEqual([first, second], [1, 2])
    }

    func testStopsFetchingWhenConsumerIsCancelled() async throws {
        let changes = ManualChangeObserver()
        let fetches = LockedCounter()
        let stream = LiveQuery(changeObserver: changes).stream { fetches.increment() }
        let consumer = Task { for try await _ in stream {} }
        await waitUntil { fetches.value == 1 }

        consumer.cancel()
        await waitUntil { changes.subscriberCount == 0 }
        changes.send()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(fetches.value, 1)
    }

    func testFetchErrorFinishesStreamWithThatError() async {
        let changes = ManualChangeObserver()
        let stream = LiveQuery(changeObserver: changes).stream { () async throws -> Int in
            throw DomainError.persistenceFailure(message: "boom")
        }

        do {
            for try await _ in stream {}
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? DomainError, .persistenceFailure(message: "boom"))
        }
    }
}

import XCTest
@testable import JobReferralTracker

@MainActor
final class CoreDataChangeObserverTests: XCTestCase {
    func testEmitsWhenThisStackSaves() async throws {
        let stack = try await TestStack.make()
        let events = LockedCounter()
        let stream = CoreDataChangeObserver(stack: stack).changes()
        let listener = Task { for await _ in stream { events.increment() } }
        defer { listener.cancel() }

        try await CoreDataJobRepository(stack: stack).create(Fixtures.job(id: 1))

        await waitUntil { events.value >= 1 }
    }

    func testIgnoresSavesFromOtherStacks() async throws {
        let observed = try await TestStack.make()
        let other = try await TestStack.make()
        let events = LockedCounter()
        let stream = CoreDataChangeObserver(stack: observed).changes()
        let listener = Task { for await _ in stream { events.increment() } }
        defer { listener.cancel() }

        try await CoreDataJobRepository(stack: other).create(Fixtures.job(id: 1))
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(events.value, 0)
    }

    func testReadsDoNotEmit() async throws {
        let stack = try await TestStack.make()
        let repository = CoreDataJobRepository(stack: stack)
        try await repository.create(Fixtures.job(id: 1))
        let events = LockedCounter()
        let stream = CoreDataChangeObserver(stack: stack).changes()
        let listener = Task { for await _ in stream { events.increment() } }
        defer { listener.cancel() }

        _ = try await repository.fetchJobSummaries()
        _ = try await repository.fetchJob(id: Fixtures.uuid(1))
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(events.value, 0)
    }
}

import XCTest
@testable import JobReferralTracker

@MainActor
final class AppBootstrapperTests: XCTestCase {
    /// A store path whose parent is a regular file, so the store can never be created.
    /// (Paths under /dev/null are treated by Core Data as in-memory stores and would load fine.)
    private static func unopenableStoreURL() throws -> URL {
        let blocker = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("not a directory".utf8).write(to: blocker)
        return blocker.appendingPathComponent("store.sqlite")
    }

    func testBecomesReadyWhenStoreLoads() async {
        let bootstrapper = AppBootstrapper(makeStack: { CoreDataStack(storeType: .inMemory) })

        await bootstrapper.bootstrap()

        guard case .ready = bootstrapper.state else { return XCTFail("Expected ready, got \(bootstrapper.state)") }
    }

    func testShowsFailureInsteadOfCrashingWhenStoreCannotOpen() async throws {
        let badURL = try Self.unopenableStoreURL()
        let bootstrapper = AppBootstrapper(makeStack: {
            let stack = CoreDataStack()
            stack.container.persistentStoreDescriptions.first?.url = badURL
            return stack
        })

        await bootstrapper.bootstrap()

        guard case .failed(let message) = bootstrapper.state else {
            return XCTFail("Expected failed, got \(bootstrapper.state)")
        }
        XCTAssertFalse(message.isEmpty)
    }

    func testRetryAfterFailureCanSucceed() async throws {
        let badURL = try Self.unopenableStoreURL()
        let attempts = LockedCounter()
        let bootstrapper = AppBootstrapper(makeStack: {
            let stack = CoreDataStack(storeType: .inMemory)
            if attempts.increment() == 1 {
                stack.container.persistentStoreDescriptions.first?.url = badURL
            }
            return stack
        })

        await bootstrapper.bootstrap()
        await bootstrapper.bootstrap()

        guard case .ready = bootstrapper.state else { return XCTFail("Expected ready after retry") }
        XCTAssertEqual(attempts.value, 2)
    }
}

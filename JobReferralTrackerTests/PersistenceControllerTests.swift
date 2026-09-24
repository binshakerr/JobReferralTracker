import CoreData
import XCTest
@testable import JobReferralTracker

final class PersistenceControllerTests: XCTestCase {
    func testInMemoryStoreLoads() {
        let controller = PersistenceController(inMemory: true)

        XCTAssertEqual(controller.container.name, "JobReferralTracker")
        XCTAssertFalse(controller.container.persistentStoreCoordinator.persistentStores.isEmpty)
    }

    func testSaveWithoutChangesDoesNotThrow() {
        let controller = PersistenceController(inMemory: true)

        XCTAssertNoThrow(try controller.save())
    }
}

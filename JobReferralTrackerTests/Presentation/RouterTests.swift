import XCTest
@testable import JobReferralTracker

@MainActor
final class RouterTests: XCTestCase {
    func testDismissRemovesRouteAndEverythingAboveIt() {
        let router = Router()
        router.path = [
            .jobDetail(jobID: Fixtures.uuid(1)),
            .referralDetail(referralID: Fixtures.uuid(2)),
            .jobDetail(jobID: Fixtures.uuid(3)),
        ]

        router.dismiss(.referralDetail(referralID: Fixtures.uuid(2)))

        XCTAssertEqual(router.path, [.jobDetail(jobID: Fixtures.uuid(1))])
    }

    func testDismissingRouteNotInPathDoesNothing() {
        let router = Router()
        router.push(.jobDetail(jobID: Fixtures.uuid(1)))

        router.dismiss(.jobDetail(jobID: Fixtures.uuid(9)))

        XCTAssertEqual(router.path, [.jobDetail(jobID: Fixtures.uuid(1))])
    }
}

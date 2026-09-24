import XCTest
@testable import JobReferralTracker

final class ReferralAnalyticsCalculatorTests: XCTestCase {
    private let calculator = ReferralAnalyticsCalculator()

    func testCountsEveryStatusPerJobAndOverall() {
        let android = Fixtures.job(id: 1, title: "Android Engineer")
        let ios = Fixtures.job(id: 2, title: "iOS Engineer")
        let web = Fixtures.job(id: 3, title: "Web Engineer")
        let referrals = [
            Fixtures.referral(id: 10, jobID: 1, status: .hired),
            Fixtures.referral(id: 11, jobID: 1, status: .interview),
            Fixtures.referral(id: 12, jobID: 1, status: .interview),
            Fixtures.referral(id: 20, jobID: 2, status: .rejected),
        ]

        let analytics = calculator.makeAnalytics(jobs: [web, ios, android], referrals: referrals)

        XCTAssertEqual(analytics.perJob.map(\.job.id), [android.id, ios.id, web.id])
        XCTAssertEqual(analytics.perJob[0].breakdown.counts,
                       [.pending: 0, .contacted: 0, .interview: 2, .hired: 1, .rejected: 0])
        XCTAssertEqual(analytics.perJob[1].breakdown.counts,
                       [.pending: 0, .contacted: 0, .interview: 0, .hired: 0, .rejected: 1])
        XCTAssertEqual(analytics.perJob[2].breakdown.counts,
                       [.pending: 0, .contacted: 0, .interview: 0, .hired: 0, .rejected: 0])
        XCTAssertEqual(analytics.overall.counts,
                       [.pending: 0, .contacted: 0, .interview: 2, .hired: 1, .rejected: 1])
        XCTAssertEqual(analytics.overall.total, 4)
    }

    func testJobsWithEqualTotalsAreSortedByTitleIgnoringCase() {
        let beta = Fixtures.job(id: 1, title: "beta")
        let alpha = Fixtures.job(id: 2, title: "Alpha")
        let referrals = [Fixtures.referral(id: 10, jobID: 1), Fixtures.referral(id: 20, jobID: 2)]

        let analytics = calculator.makeAnalytics(jobs: [beta, alpha], referrals: referrals)

        XCTAssertEqual(analytics.perJob.map(\.job.title), ["Alpha", "beta"])
    }

    func testReferralsOfUnknownJobsAreIgnored() {
        let job = Fixtures.job(id: 1)
        let referrals = [Fixtures.referral(id: 10, jobID: 1), Fixtures.referral(id: 99, jobID: 42, status: .hired)]

        let analytics = calculator.makeAnalytics(jobs: [job], referrals: referrals)

        XCTAssertEqual(analytics.overall.total, 1)
        XCTAssertEqual(analytics.overall.count(for: .hired), 0)
    }

    func testNoJobsProducesEmptyAnalytics() {
        let analytics = calculator.makeAnalytics(jobs: [], referrals: [])

        XCTAssertEqual(analytics, .empty)
        XCTAssertEqual(analytics.overall.total, 0)
    }
}

final class ReferralFilterTests: XCTestCase {
    private let items = [
        ReferralListItem(referral: Fixtures.referral(id: 1, status: .hired), jobTitle: "iOS", company: "Acme"),
        ReferralListItem(referral: Fixtures.referral(id: 2, status: .pending), jobTitle: "iOS", company: "Acme"),
        ReferralListItem(referral: Fixtures.referral(id: 3, status: .hired), jobTitle: "Web", company: "Globex"),
    ]

    func testAllKeepsEveryItemInOrder() {
        XCTAssertEqual(ReferralFilter.all.apply(to: items).map(\.id), [Fixtures.uuid(1), Fixtures.uuid(2), Fixtures.uuid(3)])
    }

    func testStatusFilterKeepsOnlyMatchingItems() {
        XCTAssertEqual(ReferralFilter.status(.hired).apply(to: items).map(\.id), [Fixtures.uuid(1), Fixtures.uuid(3)])
        XCTAssertTrue(ReferralFilter.status(.rejected).apply(to: items).isEmpty)
    }

    func testCountsIncludeAllAndEveryStatus() {
        XCTAssertEqual(ReferralFilter.counts(in: items), [
            .all: 3,
            .status(.pending): 1,
            .status(.contacted): 0,
            .status(.interview): 0,
            .status(.hired): 2,
            .status(.rejected): 0,
        ])
    }
}

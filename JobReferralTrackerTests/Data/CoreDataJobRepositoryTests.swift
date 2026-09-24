import XCTest
@testable import JobReferralTracker

final class CoreDataJobRepositoryTests: XCTestCase {
    private var stack: CoreDataStack!
    private var jobs: CoreDataJobRepository!
    private var referrals: CoreDataReferralRepository!

    override func setUp() async throws {
        stack = try await TestStack.make()
        jobs = CoreDataJobRepository(stack: stack)
        referrals = CoreDataReferralRepository(stack: stack)
    }

    func testCreatedJobRoundTripsAllFields() async throws {
        let job = Fixtures.job(id: 1)

        try await jobs.create(job)
        let fetched = try await jobs.fetchJob(id: job.id)

        XCTAssertEqual(fetched, job)
    }

    func testFetchMissingJobReturnsNil() async throws {
        let fetched = try await jobs.fetchJob(id: Fixtures.uuid(99))

        XCTAssertNil(fetched)
    }

    func testJobsAreReturnedNewestFirst() async throws {
        try await jobs.create(Fixtures.job(id: 1, title: "Oldest", createdAt: Fixtures.date1))
        try await jobs.create(Fixtures.job(id: 2, title: "Newest", createdAt: Fixtures.date3))
        try await jobs.create(Fixtures.job(id: 3, title: "Middle", createdAt: Fixtures.date2))

        let titles = try await jobs.fetchJobs().map(\.title)
        let summaryTitles = try await jobs.fetchJobSummaries().map(\.job.title)

        XCTAssertEqual(titles, ["Newest", "Middle", "Oldest"])
        XCTAssertEqual(summaryTitles, ["Newest", "Middle", "Oldest"])
    }

    func testSummariesCountEachJobsReferrals() async throws {
        try await jobs.create(Fixtures.job(id: 1, createdAt: Fixtures.date2))
        try await jobs.create(Fixtures.job(id: 2, createdAt: Fixtures.date1))
        try await referrals.create(Fixtures.referral(id: 10, jobID: 1, email: "a@example.com"))
        try await referrals.create(Fixtures.referral(id: 11, jobID: 1, email: "b@example.com"))

        let counts = try await jobs.fetchJobSummaries().map(\.referralCount)

        XCTAssertEqual(counts, [2, 0])
    }

    func testUpdateOverwritesFields() async throws {
        var job = Fixtures.job(id: 1)
        try await jobs.create(job)
        job.title = "Staff iOS Engineer"
        job.location = ""
        job.updatedAt = Fixtures.date3

        try await jobs.update(job)
        let fetched = try await jobs.fetchJob(id: job.id)

        XCTAssertEqual(fetched, job)
    }

    func testUpdatingMissingJobThrowsNotFound() async {
        let missing = Fixtures.job(id: 99)

        do {
            try await jobs.update(missing)
            XCTFail("Expected jobNotFound")
        } catch {
            XCTAssertEqual(error as? DomainError, .jobNotFound(id: missing.id))
        }
    }

    func testDeletingJobCascadesToItsReferralsOnly() async throws {
        try await jobs.create(Fixtures.job(id: 1))
        try await jobs.create(Fixtures.job(id: 2))
        try await referrals.create(Fixtures.referral(id: 10, jobID: 1))
        try await referrals.create(Fixtures.referral(id: 20, jobID: 2))

        try await jobs.deleteJob(id: Fixtures.uuid(1))

        let remainingJobs = try await jobs.fetchJobs().map(\.id)
        let remainingReferrals = try await referrals.fetchAllReferrals().map(\.id)
        XCTAssertEqual(remainingJobs, [Fixtures.uuid(2)])
        XCTAssertEqual(remainingReferrals, [Fixtures.uuid(20)])
    }

    func testDeletingMissingJobIsANoOp() async throws {
        try await jobs.create(Fixtures.job(id: 1))

        try await jobs.deleteJob(id: Fixtures.uuid(99))

        let count = try await jobs.fetchJobs().count
        XCTAssertEqual(count, 1)
    }
}

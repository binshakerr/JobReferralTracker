import CoreData
import XCTest
@testable import JobReferralTracker

final class CoreDataReferralRepositoryTests: XCTestCase {
    private var stack: CoreDataStack!
    private var jobs: CoreDataJobRepository!
    private var referrals: CoreDataReferralRepository!

    override func setUp() async throws {
        stack = try await TestStack.make()
        jobs = CoreDataJobRepository(stack: stack)
        referrals = CoreDataReferralRepository(stack: stack)
        try await jobs.create(Fixtures.job(id: 1, title: "iOS Engineer", company: "Acme"))
        try await jobs.create(Fixtures.job(id: 2, title: "Web Engineer", company: "Globex"))
    }

    func testCreatedReferralRoundTripsAllFields() async throws {
        let referral = Referral(
            id: Fixtures.uuid(10), jobID: Fixtures.uuid(1), contactName: "Jane Doe", email: "jane@example.com",
            linkedInURL: URL(string: "https://uk.linkedin.com/in/jane-doe")!, note: "Former teammate",
            status: .interview, createdAt: Fixtures.date1, updatedAt: Fixtures.date2, statusUpdatedAt: Fixtures.date3
        )

        try await referrals.create(referral)
        let fetched = try await referrals.fetchReferral(id: referral.id)

        XCTAssertEqual(fetched, referral)
    }

    func testNilNoteRoundTrips() async throws {
        let referral = Fixtures.referral(id: 10, jobID: 1)

        try await referrals.create(referral)
        let fetched = try await referrals.fetchReferral(id: referral.id)

        XCTAssertNil(fetched?.note)
    }

    func testCreatingForMissingJobThrowsJobNotFound() async {
        let orphan = Fixtures.referral(id: 10, jobID: 99)

        do {
            try await referrals.create(orphan)
            XCTFail("Expected jobNotFound")
        } catch {
            XCTAssertEqual(error as? DomainError, .jobNotFound(id: Fixtures.uuid(99)))
        }
    }

    func testFetchByJobReturnsOnlyThatJobMostRecentlyUpdatedFirst() async throws {
        try await referrals.create(Fixtures.referral(id: 10, jobID: 1, email: "a@x.com", updatedAt: Fixtures.date1))
        try await referrals.create(Fixtures.referral(id: 11, jobID: 1, email: "b@x.com", updatedAt: Fixtures.date3))
        try await referrals.create(Fixtures.referral(id: 12, jobID: 1, email: "c@x.com", updatedAt: Fixtures.date2))
        try await referrals.create(Fixtures.referral(id: 20, jobID: 2, email: "d@x.com", updatedAt: Fixtures.date3))

        let ids = try await referrals.fetchReferrals(jobID: Fixtures.uuid(1)).map(\.id)

        XCTAssertEqual(ids, [Fixtures.uuid(11), Fixtures.uuid(12), Fixtures.uuid(10)])
    }

    func testAllReferralItemsIncludeJobInfoMostRecentlyUpdatedFirst() async throws {
        try await referrals.create(Fixtures.referral(id: 10, jobID: 1, updatedAt: Fixtures.date1))
        try await referrals.create(Fixtures.referral(id: 20, jobID: 2, updatedAt: Fixtures.date2))

        let items = try await referrals.fetchAllReferralItems()

        XCTAssertEqual(items.map(\.id), [Fixtures.uuid(20), Fixtures.uuid(10)])
        XCTAssertEqual(items.map(\.jobTitle), ["Web Engineer", "iOS Engineer"])
        XCTAssertEqual(items.map(\.company), ["Globex", "Acme"])
    }

    func testReferralItemForMissingReferralIsNil() async throws {
        let item = try await referrals.fetchReferralItem(id: Fixtures.uuid(99))

        XCTAssertNil(item)
    }

    func testEmailExistsIsCaseInsensitiveScopedToJobAndHonorsExclusion() async throws {
        try await referrals.create(Fixtures.referral(id: 10, jobID: 1, email: "jane@example.com"))

        let sameJob = try await referrals.emailExists("JANE@Example.com", jobID: Fixtures.uuid(1), excludingReferralID: nil)
        let otherJob = try await referrals.emailExists("jane@example.com", jobID: Fixtures.uuid(2), excludingReferralID: nil)
        let excludingSelf = try await referrals.emailExists("jane@example.com", jobID: Fixtures.uuid(1),
                                                            excludingReferralID: Fixtures.uuid(10))
        let otherEmail = try await referrals.emailExists("sam@example.com", jobID: Fixtures.uuid(1), excludingReferralID: nil)

        XCTAssertTrue(sameJob)
        XCTAssertFalse(otherJob)
        XCTAssertFalse(excludingSelf)
        XCTAssertFalse(otherEmail)
    }

    func testUpdatePersistsChanges() async throws {
        var referral = Fixtures.referral(id: 10, jobID: 1)
        try await referrals.create(referral)
        referral.status = .hired
        referral.note = "Offer accepted"
        referral.updatedAt = Fixtures.date3
        referral.statusUpdatedAt = Fixtures.date3

        try await referrals.update(referral)
        let fetched = try await referrals.fetchReferral(id: referral.id)

        XCTAssertEqual(fetched, referral)
    }

    func testUpdatingMissingReferralThrowsNotFound() async {
        let missing = Fixtures.referral(id: 99, jobID: 1)

        do {
            try await referrals.update(missing)
            XCTFail("Expected referralNotFound")
        } catch {
            XCTAssertEqual(error as? DomainError, .referralNotFound(id: missing.id))
        }
    }

    func testDeleteRemovesReferralButKeepsJob() async throws {
        try await referrals.create(Fixtures.referral(id: 10, jobID: 1))

        try await referrals.deleteReferral(id: Fixtures.uuid(10))

        let fetched = try await referrals.fetchReferral(id: Fixtures.uuid(10))
        let job = try await jobs.fetchJob(id: Fixtures.uuid(1))
        XCTAssertNil(fetched)
        XCTAssertNotNil(job)
    }

    func testCorruptStoredStatusSurfacesAsPersistenceFailure() async throws {
        try await stack.performBackgroundTask { context in
            let job = try JobEntity.fetch(id: Fixtures.uuid(1), in: context)
            let entity = ReferralEntity(context: context)
            entity.apply(Fixtures.referral(id: 10, jobID: 1))
            entity.statusRaw = "ghosted"
            entity.job = job
        }

        do {
            _ = try await referrals.fetchAllReferrals()
            XCTFail("Expected persistenceFailure")
        } catch {
            guard case .persistenceFailure = error as? DomainError else {
                return XCTFail("Expected persistenceFailure, got \(error)")
            }
        }
    }
}

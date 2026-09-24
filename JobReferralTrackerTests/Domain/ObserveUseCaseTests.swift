import XCTest
@testable import JobReferralTracker

/// Live use cases wired through `AppContainer` over the in-memory repository.
@MainActor
final class ObserveUseCaseTests: XCTestCase {
    func testJobSummariesUpdateWhenReferralIsAdded() async throws {
        let job = Fixtures.job(id: 1)
        let env = TestEnvironment(jobs: [job])
        var summaries = env.container.observeJobSummaries.execute().makeAsyncIterator()
        let initial = try await summaries.next()

        var draft = ReferralDraft()
        draft.contactName = "Jane"
        draft.email = "jane@example.com"
        draft.linkedInProfile = "linkedin.com/in/jane"
        _ = try await env.container.addReferral.execute(jobID: job.id, draft: draft)
        let updated = try await summaries.next()

        XCTAssertEqual(initial?.map(\.referralCount), [0])
        XCTAssertEqual(updated?.map(\.referralCount), [1])
    }

    func testObservedJobBecomesNilAfterDeletion() async throws {
        let job = Fixtures.job(id: 1)
        let env = TestEnvironment(jobs: [job])
        var observed = env.container.observeJob.execute(id: job.id).makeAsyncIterator()
        let initial = try await observed.next()

        try await env.container.deleteJob.execute(id: job.id)
        let afterDelete = try await observed.next()

        XCTAssertEqual(initial, .some(job))
        XCTAssertEqual(afterDelete, .some(nil))
    }

    func testObservedReferralBecomesNilWhenItsJobIsDeleted() async throws {
        let referral = Fixtures.referral(id: 100, jobID: 1)
        let env = TestEnvironment(jobs: [Fixtures.job(id: 1)], referrals: [referral])
        var observed = env.container.observeReferral.execute(id: referral.id).makeAsyncIterator()
        let initial = try await observed.next()

        try await env.container.deleteJob.execute(id: referral.jobID)
        let afterDelete = try await observed.next()

        XCTAssertEqual(initial??.referral, referral)
        XCTAssertEqual(initial??.jobTitle, "iOS Engineer")
        XCTAssertEqual(afterDelete, .some(nil))
    }

    func testAnalyticsRecomputeAfterStatusChange() async throws {
        let referral = Fixtures.referral(id: 100, jobID: 1, status: .pending)
        let env = TestEnvironment(jobs: [Fixtures.job(id: 1)], referrals: [referral])
        var analytics = env.container.observeReferralAnalytics.execute().makeAsyncIterator()
        let initial = try await analytics.next()

        _ = try await env.container.updateReferralStatus.execute(id: referral.id, status: .hired)
        let updated = try await analytics.next()

        XCTAssertEqual(initial?.overall.count(for: .pending), 1)
        XCTAssertEqual(updated?.overall.count(for: .pending), 0)
        XCTAssertEqual(updated?.overall.count(for: .hired), 1)
    }
}

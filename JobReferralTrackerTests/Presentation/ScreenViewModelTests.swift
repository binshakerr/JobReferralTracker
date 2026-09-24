import XCTest
@testable import JobReferralTracker

@MainActor
final class JobListViewModelTests: XCTestCase {
    func testLoadsSummariesAndUpdatesWhenJobsChange() async throws {
        let env = TestEnvironment(jobs: [Fixtures.job(id: 1, createdAt: Fixtures.date1)])
        let viewModel = env.container.makeJobListViewModel()
        let observation = Task { await viewModel.observe() }
        defer { observation.cancel() }
        await waitUntil { viewModel.state.value?.count == 1 }

        try await env.repository.create(Fixtures.job(id: 2, title: "Newer", createdAt: Fixtures.date3))

        await waitUntil { viewModel.state.value?.count == 2 }
        XCTAssertEqual(viewModel.state.value?.first?.job.title, "Newer")
    }

    func testLoadFailureShowsFailedState() async {
        let env = TestEnvironment()
        await env.repository.failReads(with: DomainError.persistenceFailure(message: "Unreadable"))
        let viewModel = env.container.makeJobListViewModel()

        await viewModel.observe()

        guard case .failed(let message) = viewModel.state else { return XCTFail("Expected failed state") }
        XCTAssertEqual(message, "Unreadable")
    }

    func testDeleteRemovesJob() async {
        let job = Fixtures.job(id: 1)
        let env = TestEnvironment(jobs: [job])
        let viewModel = env.container.makeJobListViewModel()

        await viewModel.delete(JobSummary(job: job, referralCount: 0))

        let stored = await env.repository.jobs
        XCTAssertTrue(stored.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testDeleteFailureShowsMessage() async {
        let job = Fixtures.job(id: 1)
        let env = TestEnvironment(jobs: [job])
        await env.repository.failWrites(with: DomainError.persistenceFailure(message: "Locked"))
        let viewModel = env.container.makeJobListViewModel()

        await viewModel.delete(JobSummary(job: job, referralCount: 0))

        XCTAssertEqual(viewModel.errorMessage, "Locked")
    }
}

@MainActor
final class JobDetailViewModelTests: XCTestCase {
    func testLoadsJobReferralsAndStatusBreakdown() async {
        let job = Fixtures.job(id: 1)
        let env = TestEnvironment(jobs: [job], referrals: [
            Fixtures.referral(id: 10, jobID: 1, email: "a@x.com", status: .interview),
            Fixtures.referral(id: 11, jobID: 1, email: "b@x.com", status: .interview),
            Fixtures.referral(id: 12, jobID: 1, email: "c@x.com", status: .hired),
            Fixtures.referral(id: 20, jobID: 2, email: "d@x.com", status: .rejected),
        ])
        let viewModel = env.container.makeJobDetailViewModel(jobID: job.id)
        let observation = Task { await viewModel.observe() }
        defer { observation.cancel() }

        await waitUntil { viewModel.state.value != nil && viewModel.referrals.count == 3 }

        XCTAssertEqual(viewModel.state.value, job)
        XCTAssertEqual(viewModel.breakdown.count(for: .interview), 2)
        XCTAssertEqual(viewModel.breakdown.count(for: .hired), 1)
        XCTAssertEqual(viewModel.breakdown.count(for: .rejected), 0)
    }

    func testJobDeletedElsewhereMarksScreenDeleted() async throws {
        let job = Fixtures.job(id: 1)
        let env = TestEnvironment(jobs: [job])
        let viewModel = env.container.makeJobDetailViewModel(jobID: job.id)
        let observation = Task { await viewModel.observe() }
        defer { observation.cancel() }
        await waitUntil { viewModel.state.value != nil }

        try await env.repository.deleteJob(id: job.id)

        await waitUntil { viewModel.isDeleted }
    }

    func testDeletingJobMarksScreenDeleted() async {
        let job = Fixtures.job(id: 1)
        let env = TestEnvironment(jobs: [job])
        let viewModel = env.container.makeJobDetailViewModel(jobID: job.id)

        await viewModel.deleteJob()

        XCTAssertTrue(viewModel.isDeleted)
        let stored = await env.repository.jobs
        XCTAssertTrue(stored.isEmpty)
    }

    func testDeletingReferralKeepsJob() async {
        let referral = Fixtures.referral(id: 10, jobID: 1)
        let env = TestEnvironment(jobs: [Fixtures.job(id: 1)], referrals: [referral])
        let viewModel = env.container.makeJobDetailViewModel(jobID: Fixtures.uuid(1))

        await viewModel.delete(referral)

        let referrals = await env.repository.referrals
        XCTAssertTrue(referrals.isEmpty)
        XCTAssertFalse(viewModel.isDeleted)
    }
}

@MainActor
final class ReferralDetailViewModelTests: XCTestCase {
    private let referral = Fixtures.referral(id: 10, jobID: 1, status: .pending)

    private func makeLoadedViewModel(_ env: TestEnvironment) async -> (ReferralDetailViewModel, Task<Void, Never>) {
        let viewModel = env.container.makeReferralDetailViewModel(referralID: referral.id)
        let observation = Task { await viewModel.observe() }
        await waitUntil { viewModel.state.value != nil }
        return (viewModel, observation)
    }

    func testSetStatusPersistsAndUpdatesScreen() async {
        let env = TestEnvironment(jobs: [Fixtures.job(id: 1)], referrals: [referral])
        let (viewModel, observation) = await makeLoadedViewModel(env)
        defer { observation.cancel() }

        await viewModel.setStatus(.hired)

        XCTAssertEqual(viewModel.state.value?.referral.status, .hired)
        let stored = await env.repository.referrals[referral.id]
        XCTAssertEqual(stored?.status, .hired)
        XCTAssertEqual(stored?.statusUpdatedAt, Fixtures.date2)
    }

    func testSetStatusRevertsAndShowsMessageWhenSaveFails() async {
        let env = TestEnvironment(jobs: [Fixtures.job(id: 1)], referrals: [referral])
        let (viewModel, observation) = await makeLoadedViewModel(env)
        defer { observation.cancel() }
        await env.repository.failWrites(with: DomainError.persistenceFailure(message: "Disk full"))

        await viewModel.setStatus(.hired)

        XCTAssertEqual(viewModel.state.value?.referral.status, .pending)
        XCTAssertEqual(viewModel.errorMessage, "Disk full")
    }

    func testDeleteMarksScreenDeleted() async {
        let env = TestEnvironment(jobs: [Fixtures.job(id: 1)], referrals: [referral])
        let viewModel = env.container.makeReferralDetailViewModel(referralID: referral.id)

        await viewModel.delete()

        XCTAssertTrue(viewModel.isDeleted)
        let stored = await env.repository.referrals
        XCTAssertTrue(stored.isEmpty)
    }

    func testReferralRemovedByJobDeletionMarksScreenDeleted() async throws {
        let env = TestEnvironment(jobs: [Fixtures.job(id: 1)], referrals: [referral])
        let (viewModel, observation) = await makeLoadedViewModel(env)
        defer { observation.cancel() }

        try await env.repository.deleteJob(id: Fixtures.uuid(1))

        await waitUntil { viewModel.isDeleted }
    }
}

@MainActor
final class AnalyticsViewModelTests: XCTestCase {
    func testLoadsAnalyticsAndFiltersAllReferrals() async {
        let env = TestEnvironment(jobs: [Fixtures.job(id: 1), Fixtures.job(id: 2, title: "Web")], referrals: [
            Fixtures.referral(id: 10, jobID: 1, email: "a@x.com", status: .hired),
            Fixtures.referral(id: 11, jobID: 1, email: "b@x.com", status: .pending),
            Fixtures.referral(id: 20, jobID: 2, email: "c@x.com", status: .hired),
        ])
        let viewModel = env.container.makeAnalyticsViewModel()
        let observation = Task { await viewModel.observe() }
        defer { observation.cancel() }
        await waitUntil { viewModel.analytics.value != nil && viewModel.allReferrals.value != nil }

        XCTAssertEqual(viewModel.analytics.value?.overall.total, 3)
        XCTAssertEqual(viewModel.filteredReferrals.count, 3)
        XCTAssertEqual(viewModel.filterCounts[.all], 3)
        XCTAssertEqual(viewModel.filterCounts[.status(.hired)], 2)

        viewModel.filter = .status(.hired)

        XCTAssertEqual(Set(viewModel.filteredReferrals.map(\.id)), [Fixtures.uuid(10), Fixtures.uuid(20)])
        XCTAssertEqual(viewModel.filterCounts[.all], 3, "Counts ignore the active filter")
    }

    func testUpdatesWhenReferralStatusChanges() async throws {
        let referral = Fixtures.referral(id: 10, jobID: 1, status: .pending)
        let env = TestEnvironment(jobs: [Fixtures.job(id: 1)], referrals: [referral])
        let viewModel = env.container.makeAnalyticsViewModel()
        let observation = Task { await viewModel.observe() }
        defer { observation.cancel() }
        await waitUntil { viewModel.analytics.value != nil }

        _ = try await env.container.updateReferralStatus.execute(id: referral.id, status: .rejected)

        await waitUntil { viewModel.analytics.value?.overall.count(for: .rejected) == 1 }
        await waitUntil { viewModel.filterCounts[.status(.rejected)] == 1 }
    }
}

final class PresentationFormattingTests: XCTestCase {
    func testBreakdownSummaryListsNonZeroStatusesInPipelineOrder() {
        let breakdown = StatusBreakdown(statuses: [.hired, .interview, .interview, .pending])

        XCTAssertEqual(breakdown.summaryText, "Pending 1 · Interview 2 · Hired 1")
        XCTAssertEqual(StatusBreakdown.empty.summaryText, "No referrals yet")
    }

    func testReferralCountTextPluralizes() {
        XCTAssertEqual(referralCountText(0), "0 referrals")
        XCTAssertEqual(referralCountText(1), "1 referral")
        XCTAssertEqual(referralCountText(2), "2 referrals")
    }

    func testDomainErrorsMapToReadableMessages() {
        XCTAssertEqual(DomainError.persistenceFailure(message: "Disk full").userMessage, "Disk full")
        XCTAssertEqual(DomainError.jobNotFound(id: Fixtures.uuid(1)).userMessage, "This job no longer exists.")
    }
}

import XCTest
@testable import JobReferralTracker

@MainActor
final class ReferralFormViewModelTests: XCTestCase {
    private let job = Fixtures.job(id: 1)

    private func fill(_ viewModel: ReferralFormViewModel, email: String = "sam@example.com") {
        viewModel.binding(\.contactName, field: .contactName).wrappedValue = "Sam Lee"
        viewModel.binding(\.email, field: .email).wrappedValue = email
        viewModel.binding(\.linkedInProfile, field: .linkedInProfile).wrappedValue = "linkedin.com/in/samlee"
    }

    func testCreateAddsReferralToJob() async {
        let env = TestEnvironment(jobs: [job])
        let viewModel = env.container.makeReferralFormViewModel(mode: .create(jobID: job.id))
        fill(viewModel)
        viewModel.status.wrappedValue = .contacted

        let saved = await viewModel.save()

        XCTAssertTrue(saved)
        let stored = await env.repository.referrals.values.first
        XCTAssertEqual(stored?.jobID, job.id)
        XCTAssertEqual(stored?.email, "sam@example.com")
        XCTAssertEqual(stored?.status, .contacted)
    }

    func testDuplicateEmailIsShownInlineAndBlocksSave() async {
        let existing = Fixtures.referral(id: 100, jobID: 1, email: "jane@example.com")
        let env = TestEnvironment(jobs: [job], referrals: [existing])
        let viewModel = env.container.makeReferralFormViewModel(mode: .create(jobID: job.id))
        fill(viewModel, email: "Jane@Example.com")
        XCTAssertTrue(viewModel.canSave, "Duplicates are only known after asking the repository")

        let saved = await viewModel.save()

        XCTAssertFalse(saved)
        XCTAssertEqual(viewModel.validation[.email], .duplicateEmail)
        XCTAssertNotNil(viewModel.errorMessage(for: .email))
        XCTAssertFalse(viewModel.canSave)
        XCTAssertNil(viewModel.errorMessage, "Shown inline, not as an alert")
        let count = await env.repository.referrals.count
        XCTAssertEqual(count, 1)
    }

    func testEditingEmailClearsDuplicateIssue() async {
        let existing = Fixtures.referral(id: 100, jobID: 1, email: "jane@example.com")
        let env = TestEnvironment(jobs: [job], referrals: [existing])
        let viewModel = env.container.makeReferralFormViewModel(mode: .create(jobID: job.id))
        fill(viewModel, email: "jane@example.com")
        _ = await viewModel.save()

        viewModel.binding(\.email, field: .email).wrappedValue = "sam@example.com"

        XCTAssertNil(viewModel.validation[.email])
        XCTAssertTrue(viewModel.canSave)
    }

    func testEditModeRequiresChangeAndUpdatesReferral() async {
        let referral = Fixtures.referral(id: 100, jobID: 1, status: .pending)
        let env = TestEnvironment(jobs: [job], referrals: [referral])
        let viewModel = env.container.makeReferralFormViewModel(mode: .edit(referral))
        XCTAssertFalse(viewModel.canSave)

        viewModel.status.wrappedValue = .interview
        let saved = await viewModel.save()

        XCTAssertTrue(saved)
        let stored = await env.repository.referrals[referral.id]
        XCTAssertEqual(stored?.status, .interview)
    }
}

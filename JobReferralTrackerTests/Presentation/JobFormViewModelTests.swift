import XCTest
@testable import JobReferralTracker

@MainActor
final class JobFormViewModelTests: XCTestCase {
    private func fill(_ viewModel: JobFormViewModel, title: String, company: String) {
        viewModel.binding(\.title, field: .title).wrappedValue = title
        viewModel.binding(\.company, field: .company).wrappedValue = company
    }

    func testCreateModeCannotSaveUntilRequiredFieldsAreValid() {
        let viewModel = TestEnvironment().container.makeJobFormViewModel(mode: .create)
        XCTAssertFalse(viewModel.canSave)

        fill(viewModel, title: "iOS Engineer", company: "")
        XCTAssertFalse(viewModel.canSave)

        fill(viewModel, title: "iOS Engineer", company: "Acme")
        XCTAssertTrue(viewModel.canSave)
    }

    func testErrorsShowOnlyForFieldsTheUserEdited() {
        let viewModel = TestEnvironment().container.makeJobFormViewModel(mode: .create)
        XCTAssertNil(viewModel.errorMessage(for: .title))

        viewModel.binding(\.title, field: .title).wrappedValue = "   "

        XCTAssertNotNil(viewModel.errorMessage(for: .title))
        XCTAssertNil(viewModel.errorMessage(for: .company), "Company is invalid but untouched")
    }

    func testSavingInvalidFormRevealsAllErrorsAndDoesNotSave() async {
        let env = TestEnvironment()
        let viewModel = env.container.makeJobFormViewModel(mode: .create)

        let saved = await viewModel.save()

        XCTAssertFalse(saved)
        XCTAssertNotNil(viewModel.errorMessage(for: .title))
        XCTAssertNotNil(viewModel.errorMessage(for: .company))
        let stored = await env.repository.jobs
        XCTAssertTrue(stored.isEmpty)
    }

    func testSaveInCreateModeStoresJob() async {
        let env = TestEnvironment()
        let viewModel = env.container.makeJobFormViewModel(mode: .create)
        fill(viewModel, title: " iOS Engineer ", company: "Acme")

        let saved = await viewModel.save()

        XCTAssertTrue(saved)
        let stored = await env.repository.jobs.values.map(\.title)
        XCTAssertEqual(stored, ["iOS Engineer"])
    }

    func testEditModeIsPrefilledAndRequiresAChange() {
        let job = Fixtures.job(id: 1)
        let viewModel = TestEnvironment(jobs: [job]).container.makeJobFormViewModel(mode: .edit(job))

        XCTAssertEqual(viewModel.draft, JobDraft(job: job))
        XCTAssertFalse(viewModel.hasChanges)
        XCTAssertFalse(viewModel.canSave)

        viewModel.binding(\.location, field: .location).wrappedValue = "Berlin"

        XCTAssertTrue(viewModel.hasChanges)
        XCTAssertTrue(viewModel.canSave)
    }

    func testSaveInEditModeUpdatesExistingJob() async {
        let job = Fixtures.job(id: 1)
        let env = TestEnvironment(jobs: [job])
        let viewModel = env.container.makeJobFormViewModel(mode: .edit(job))
        viewModel.binding(\.location, field: .location).wrappedValue = "Berlin"

        let saved = await viewModel.save()

        XCTAssertTrue(saved)
        let stored = await env.repository.jobs[job.id]
        XCTAssertEqual(stored?.location, "Berlin")
        XCTAssertEqual(stored?.updatedAt, Fixtures.date2)
    }

    func testStorageFailureShowsMessageAndKeepsForm() async {
        let env = TestEnvironment()
        await env.repository.failWrites(with: DomainError.persistenceFailure(message: "Disk full"))
        let viewModel = env.container.makeJobFormViewModel(mode: .create)
        fill(viewModel, title: "iOS Engineer", company: "Acme")

        let saved = await viewModel.save()

        XCTAssertFalse(saved)
        XCTAssertEqual(viewModel.errorMessage, "Disk full")
        XCTAssertEqual(viewModel.draft.title, "iOS Engineer")
        XCTAssertFalse(viewModel.isSaving)
    }
}

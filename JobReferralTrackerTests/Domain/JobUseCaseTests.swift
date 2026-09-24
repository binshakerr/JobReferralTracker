import XCTest
@testable import JobReferralTracker

final class CreateJobUseCaseTests: XCTestCase {
    func testCreatesJobWithNormalizedFieldsAndTimestamps() async throws {
        let repository = InMemoryRepository()
        let ids = SequentialIDs(startingAt: 7)
        let useCase = CreateJobUseCase(repository: repository, validator: JobValidator(),
                                       now: { Fixtures.date2 }, makeID: ids.make)
        var draft = JobDraft()
        draft.title = "  iOS Engineer "
        draft.company = " Acme\n"
        draft.location = " Remote "
        draft.jobDescription = " Build apps. "

        let job = try await useCase.execute(draft)

        let expected = Job(id: Fixtures.uuid(7), title: "iOS Engineer", company: "Acme", location: "Remote",
                           jobDescription: "Build apps.", createdAt: Fixtures.date2, updatedAt: Fixtures.date2)
        XCTAssertEqual(job, expected)
        let stored = await repository.jobs
        XCTAssertEqual(stored, [expected.id: expected])
    }

    func testRejectsEmptyTitleWithoutSaving() async {
        let repository = InMemoryRepository()
        let useCase = CreateJobUseCase(repository: repository, validator: JobValidator(),
                                       now: { Fixtures.date1 }, makeID: { Fixtures.uuid(1) })
        var draft = JobDraft()
        draft.company = "Acme"

        do {
            _ = try await useCase.execute(draft)
            XCTFail("Expected invalidJob error")
        } catch {
            XCTAssertEqual(error as? DomainError, .invalidJob(ValidationResult(issues: [.title: .required])))
        }
        let stored = await repository.jobs
        XCTAssertTrue(stored.isEmpty)
    }
}

final class UpdateJobUseCaseTests: XCTestCase {
    private func makeUseCase(_ repository: InMemoryRepository) -> UpdateJobUseCase {
        UpdateJobUseCase(repository: repository, validator: JobValidator(), now: { Fixtures.date3 })
    }

    func testAppliesNormalizedDraftAndBumpsUpdatedAtOnly() async throws {
        let original = Fixtures.job(id: 1, createdAt: Fixtures.date1)
        let repository = InMemoryRepository(jobs: [original])
        var draft = JobDraft(job: original)
        draft.title = " Senior iOS Engineer "
        draft.location = ""

        let updated = try await makeUseCase(repository).execute(id: original.id, draft: draft)

        let expected = Job(id: original.id, title: "Senior iOS Engineer", company: "Acme", location: "",
                           jobDescription: "Build apps.", createdAt: Fixtures.date1, updatedAt: Fixtures.date3)
        XCTAssertEqual(updated, expected)
        let stored = await repository.jobs[original.id]
        XCTAssertEqual(stored, expected)
    }

    func testMissingJobThrowsNotFound() async {
        let missingID = Fixtures.uuid(99)
        var draft = JobDraft()
        draft.title = "iOS Engineer"
        draft.company = "Acme"

        do {
            _ = try await makeUseCase(InMemoryRepository()).execute(id: missingID, draft: draft)
            XCTFail("Expected jobNotFound")
        } catch {
            XCTAssertEqual(error as? DomainError, .jobNotFound(id: missingID))
        }
    }

    func testInvalidDraftLeavesStoredJobUnchanged() async {
        let original = Fixtures.job()
        let repository = InMemoryRepository(jobs: [original])
        var draft = JobDraft(job: original)
        draft.company = " "

        do {
            _ = try await makeUseCase(repository).execute(id: original.id, draft: draft)
            XCTFail("Expected invalidJob")
        } catch {
            XCTAssertEqual(error as? DomainError, .invalidJob(ValidationResult(issues: [.company: .required])))
        }
        let stored = await repository.jobs[original.id]
        XCTAssertEqual(stored, original)
    }
}

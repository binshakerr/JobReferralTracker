import XCTest
@testable import JobReferralTracker

private func draft(
    name: String = "Jane Doe",
    email: String = "jane@example.com",
    linkedIn: String = "https://www.linkedin.com/in/janedoe",
    note: String = "",
    status: ReferralStatus = .pending
) -> ReferralDraft {
    var draft = ReferralDraft()
    draft.contactName = name
    draft.email = email
    draft.linkedInProfile = linkedIn
    draft.note = note
    draft.status = status
    return draft
}

final class AddReferralUseCaseTests: XCTestCase {
    private let job = Fixtures.job(id: 1)

    private func makeUseCase(_ repository: InMemoryRepository) -> AddReferralUseCase {
        let ids = SequentialIDs(startingAt: 500)
        return AddReferralUseCase(repository: repository, validator: ReferralValidator(),
                                  now: { Fixtures.date2 }, makeID: { ids.make() })
    }

    func testAddsNormalizedPendingReferralWithTimestamps() async throws {
        let repository = InMemoryRepository(jobs: [job])

        let referral = try await makeUseCase(repository).execute(jobID: job.id, draft: draft(
            name: "  Jane Doe ", email: " Jane@Example.COM ", linkedIn: " linkedin.com/in/jane ", note: "  Met at WWDC. "
        ))

        let expected = Referral(
            id: Fixtures.uuid(500), jobID: job.id, contactName: "Jane Doe", email: "jane@example.com",
            linkedInURL: URL(string: "https://linkedin.com/in/jane")!, note: "Met at WWDC.", status: .pending,
            createdAt: Fixtures.date2, updatedAt: Fixtures.date2, statusUpdatedAt: Fixtures.date2
        )
        XCTAssertEqual(referral, expected)
        let stored = await repository.referrals
        XCTAssertEqual(stored, [expected.id: expected])
    }

    func testBlankNoteIsStoredAsNil() async throws {
        let repository = InMemoryRepository(jobs: [job])

        let referral = try await makeUseCase(repository).execute(jobID: job.id, draft: draft(note: " \n "))

        XCTAssertNil(referral.note)
    }

    func testUsesStatusChosenInForm() async throws {
        let repository = InMemoryRepository(jobs: [job])

        let referral = try await makeUseCase(repository).execute(jobID: job.id, draft: draft(status: .contacted))

        XCTAssertEqual(referral.status, .contacted)
    }

    func testRejectsEmailAlreadyUsedInSameJobIgnoringCase() async {
        let existing = Fixtures.referral(id: 100, jobID: 1, email: "jane@example.com")
        let repository = InMemoryRepository(jobs: [job], referrals: [existing])

        do {
            _ = try await makeUseCase(repository).execute(jobID: job.id, draft: draft(email: "JANE@example.com"))
            XCTFail("Expected duplicate email error")
        } catch {
            XCTAssertEqual(error as? DomainError, .invalidReferral(ValidationResult(issues: [.email: .duplicateEmail])))
        }
        let count = await repository.referrals.count
        XCTAssertEqual(count, 1)
    }

    func testAllowsSameEmailForDifferentJob() async throws {
        let otherJob = Fixtures.job(id: 2)
        let existing = Fixtures.referral(id: 100, jobID: 1, email: "jane@example.com")
        let repository = InMemoryRepository(jobs: [job, otherJob], referrals: [existing])

        let referral = try await makeUseCase(repository).execute(jobID: otherJob.id, draft: draft(email: "jane@example.com"))

        XCTAssertEqual(referral.jobID, otherJob.id)
    }

    func testReportsEveryInvalidFieldWithoutSaving() async {
        let repository = InMemoryRepository(jobs: [job])

        do {
            _ = try await makeUseCase(repository).execute(jobID: job.id, draft: draft(
                name: " ", email: "jane@", linkedIn: "https://example.com/in/jane"
            ))
            XCTFail("Expected invalidReferral")
        } catch {
            XCTAssertEqual(error as? DomainError, .invalidReferral(ValidationResult(issues: [
                .contactName: .required, .email: .invalidEmail, .linkedInProfile: .invalidLinkedInURL,
            ])))
        }
        let stored = await repository.referrals
        XCTAssertTrue(stored.isEmpty)
    }

    func testMissingJobThrowsJobNotFound() async {
        let missing = Fixtures.uuid(99)

        do {
            _ = try await makeUseCase(InMemoryRepository()).execute(jobID: missing, draft: draft())
            XCTFail("Expected jobNotFound")
        } catch {
            XCTAssertEqual(error as? DomainError, .jobNotFound(id: missing))
        }
    }
}

final class UpdateReferralUseCaseTests: XCTestCase {
    private func makeUseCase(_ repository: InMemoryRepository) -> UpdateReferralUseCase {
        UpdateReferralUseCase(repository: repository, validator: ReferralValidator(), now: { Fixtures.date3 })
    }

    func testEditWithoutStatusChangeKeepsStatusTimestamp() async throws {
        let original = Fixtures.referral(id: 100, jobID: 1, status: .contacted)
        let repository = InMemoryRepository(jobs: [Fixtures.job(id: 1)], referrals: [original])
        var edit = ReferralDraft(referral: original)
        edit.contactName = "Jane Smith"
        edit.note = "Moved teams"

        let updated = try await makeUseCase(repository).execute(id: original.id, draft: edit)

        XCTAssertEqual(updated.contactName, "Jane Smith")
        XCTAssertEqual(updated.note, "Moved teams")
        XCTAssertEqual(updated.status, .contacted)
        XCTAssertEqual(updated.id, original.id)
        XCTAssertEqual(updated.jobID, original.jobID)
        XCTAssertEqual(updated.createdAt, Fixtures.date1)
        XCTAssertEqual(updated.updatedAt, Fixtures.date3)
        XCTAssertEqual(updated.statusUpdatedAt, Fixtures.date1)
        let stored = await repository.referrals[original.id]
        XCTAssertEqual(stored, updated)
    }

    func testStatusChangeUpdatesStatusTimestamp() async throws {
        let original = Fixtures.referral(id: 100, jobID: 1, status: .pending)
        let repository = InMemoryRepository(jobs: [Fixtures.job(id: 1)], referrals: [original])
        var edit = ReferralDraft(referral: original)
        edit.status = .interview

        let updated = try await makeUseCase(repository).execute(id: original.id, draft: edit)

        XCTAssertEqual(updated.status, .interview)
        XCTAssertEqual(updated.statusUpdatedAt, Fixtures.date3)
    }

    func testKeepingOwnEmailIsNotADuplicate() async throws {
        let original = Fixtures.referral(id: 100, jobID: 1, email: "jane@example.com")
        let repository = InMemoryRepository(jobs: [Fixtures.job(id: 1)], referrals: [original])

        let updated = try await makeUseCase(repository).execute(id: original.id, draft: ReferralDraft(referral: original))

        XCTAssertEqual(updated.email, "jane@example.com")
    }

    func testEmailOfAnotherReferralInSameJobIsDuplicate() async {
        let jane = Fixtures.referral(id: 100, jobID: 1, email: "jane@example.com")
        let sam = Fixtures.referral(id: 101, jobID: 1, email: "sam@example.com")
        let repository = InMemoryRepository(jobs: [Fixtures.job(id: 1)], referrals: [jane, sam])
        var edit = ReferralDraft(referral: sam)
        edit.email = "Jane@Example.com"

        do {
            _ = try await makeUseCase(repository).execute(id: sam.id, draft: edit)
            XCTFail("Expected duplicate email error")
        } catch {
            XCTAssertEqual(error as? DomainError, .invalidReferral(ValidationResult(issues: [.email: .duplicateEmail])))
        }
        let stored = await repository.referrals[sam.id]
        XCTAssertEqual(stored, sam)
    }

    func testMissingReferralThrowsNotFound() async {
        let missing = Fixtures.uuid(99)

        do {
            _ = try await makeUseCase(InMemoryRepository()).execute(id: missing, draft: draft())
            XCTFail("Expected referralNotFound")
        } catch {
            XCTAssertEqual(error as? DomainError, .referralNotFound(id: missing))
        }
    }
}

final class UpdateReferralStatusUseCaseTests: XCTestCase {
    private func makeUseCase(_ repository: InMemoryRepository) -> UpdateReferralStatusUseCase {
        UpdateReferralStatusUseCase(repository: repository, now: { Fixtures.date3 })
    }

    func testChangesStatusAndBothTimestamps() async throws {
        let original = Fixtures.referral(id: 100, status: .pending)
        let repository = InMemoryRepository(jobs: [Fixtures.job(id: 1)], referrals: [original])

        let updated = try await makeUseCase(repository).execute(id: original.id, status: .hired)

        XCTAssertEqual(updated.status, .hired)
        XCTAssertEqual(updated.updatedAt, Fixtures.date3)
        XCTAssertEqual(updated.statusUpdatedAt, Fixtures.date3)
        XCTAssertEqual(updated.createdAt, Fixtures.date1)
        let stored = await repository.referrals[original.id]
        XCTAssertEqual(stored, updated)
    }

    func testSameStatusChangesNothing() async throws {
        let original = Fixtures.referral(id: 100, status: .interview)
        let writes = LockedCounter()
        let repository = InMemoryRepository(jobs: [Fixtures.job(id: 1)], referrals: [original],
                                            onChange: { writes.increment() })

        let result = try await makeUseCase(repository).execute(id: original.id, status: .interview)

        XCTAssertEqual(result, original)
        XCTAssertEqual(writes.value, 0)
    }

    func testMissingReferralThrowsNotFound() async {
        let missing = Fixtures.uuid(99)

        do {
            _ = try await makeUseCase(InMemoryRepository()).execute(id: missing, status: .hired)
            XCTFail("Expected referralNotFound")
        } catch {
            XCTAssertEqual(error as? DomainError, .referralNotFound(id: missing))
        }
    }
}

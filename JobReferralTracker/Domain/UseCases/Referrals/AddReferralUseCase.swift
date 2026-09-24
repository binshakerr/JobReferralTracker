import Foundation

struct AddReferralUseCase: Sendable {
    let repository: ReferralRepository
    let validator: ReferralValidator
    let now: DateProvider
    let makeID: IDGenerator

    /// Throws `DomainError.invalidReferral` (including a duplicate email in this job)
    /// or `DomainError.jobNotFound`.
    func execute(jobID: UUID, draft: ReferralDraft) async throws -> Referral {
        let fields = try await validator.validatedFields(
            for: draft, jobID: jobID, excludingReferralID: nil, repository: repository
        )
        let timestamp = now()
        let referral = Referral(
            id: makeID(),
            jobID: jobID,
            contactName: fields.contactName,
            email: fields.email,
            linkedInURL: fields.linkedInURL,
            note: fields.note,
            status: fields.status,
            createdAt: timestamp,
            updatedAt: timestamp,
            statusUpdatedAt: timestamp
        )
        try await repository.create(referral)
        return referral
    }
}

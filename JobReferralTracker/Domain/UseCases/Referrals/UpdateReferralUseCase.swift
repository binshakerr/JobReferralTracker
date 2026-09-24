import Foundation

struct UpdateReferralUseCase: Sendable {
    let repository: ReferralRepository
    let validator: ReferralValidator
    let now: DateProvider

    /// Throws `DomainError.referralNotFound` or `DomainError.invalidReferral`.
    func execute(id: UUID, draft: ReferralDraft) async throws -> Referral {
        guard var referral = try await repository.fetchReferral(id: id) else {
            throw DomainError.referralNotFound(id: id)
        }
        let fields = try await validator.validatedFields(
            for: draft, jobID: referral.jobID, excludingReferralID: id, repository: repository
        )

        let timestamp = now()
        if fields.status != referral.status {
            referral.statusUpdatedAt = timestamp
        }
        referral.contactName = fields.contactName
        referral.email = fields.email
        referral.linkedInURL = fields.linkedInURL
        referral.note = fields.note
        referral.status = fields.status
        referral.updatedAt = timestamp
        try await repository.update(referral)
        return referral
    }
}

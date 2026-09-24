import Foundation

/// Validated, normalized referral fields ready to be stored.
struct NormalizedReferralFields: Sendable {
    let contactName: String
    let email: String
    let linkedInURL: URL
    let note: String?
    let status: ReferralStatus
}

extension ReferralValidator {
    /// Validates the draft, including the per-job unique email rule, and returns normalized fields.
    /// Throws `DomainError.invalidReferral` with every issue found.
    func validatedFields(
        for draft: ReferralDraft,
        jobID: UUID,
        excludingReferralID: UUID?,
        repository: ReferralRepository
    ) async throws -> NormalizedReferralFields {
        var validation = validate(draft)
        let email = normalizedEmail(draft.email)

        if validation[.email] == nil,
           try await repository.emailExists(email, jobID: jobID, excludingReferralID: excludingReferralID) {
            validation.issues[.email] = .duplicateEmail
        }
        guard validation.isValid, let linkedInURL = normalizedLinkedInURL(draft.linkedInProfile) else {
            throw DomainError.invalidReferral(validation)
        }

        return NormalizedReferralFields(
            contactName: draft.contactName.trimmed,
            email: email,
            linkedInURL: linkedInURL,
            note: normalizedNote(draft.note),
            status: draft.status
        )
    }
}

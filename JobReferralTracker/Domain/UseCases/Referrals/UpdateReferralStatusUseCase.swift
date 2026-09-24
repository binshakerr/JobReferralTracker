import Foundation

struct UpdateReferralStatusUseCase: Sendable {
    let repository: ReferralRepository
    let now: DateProvider

    /// Sets the status and its timestamps. Does nothing if the status is unchanged.
    func execute(id: UUID, status: ReferralStatus) async throws -> Referral {
        guard var referral = try await repository.fetchReferral(id: id) else {
            throw DomainError.referralNotFound(id: id)
        }
        guard referral.status != status else { return referral }

        let timestamp = now()
        referral.status = status
        referral.statusUpdatedAt = timestamp
        referral.updatedAt = timestamp
        try await repository.update(referral)
        return referral
    }
}

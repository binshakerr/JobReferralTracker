import Foundation

/// Live referrals of one job, most recently updated first.
struct ObserveReferralsUseCase: Sendable {
    let repository: ReferralRepository
    let liveQuery: LiveQuery

    func execute(jobID: UUID) -> AsyncThrowingStream<[Referral], Error> {
        liveQuery.stream { [repository] in try await repository.fetchReferrals(jobID: jobID) }
    }
}

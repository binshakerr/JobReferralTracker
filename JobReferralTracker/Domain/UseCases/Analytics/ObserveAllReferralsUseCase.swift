import Foundation

/// Live unified list of every referral across all jobs, most recently updated first.
/// Filter it with `ReferralFilter`.
struct ObserveAllReferralsUseCase: Sendable {
    let repository: ReferralRepository
    let liveQuery: LiveQuery

    func execute() -> AsyncThrowingStream<[ReferralListItem], Error> {
        liveQuery.stream { [repository] in try await repository.fetchAllReferralItems() }
    }
}

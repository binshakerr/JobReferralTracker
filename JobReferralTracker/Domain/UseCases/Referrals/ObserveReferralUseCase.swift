import Foundation

/// Live referral (with its job's title and company) for the tracking screen.
/// Yields `nil` once the referral or its job is deleted.
struct ObserveReferralUseCase: Sendable {
    let repository: ReferralRepository
    let liveQuery: LiveQuery

    func execute(id: UUID) -> AsyncThrowingStream<ReferralListItem?, Error> {
        liveQuery.stream { [repository] in try await repository.fetchReferralItem(id: id) }
    }
}

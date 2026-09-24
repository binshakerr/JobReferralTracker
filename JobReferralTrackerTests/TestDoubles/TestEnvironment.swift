import Foundation
@testable import JobReferralTracker

/// Real `AppContainer` wiring on top of the in-memory fake repository.
/// Every repository write triggers a change notification, like Core Data saves do.
@MainActor
final class TestEnvironment {
    let changes = ManualChangeObserver()
    let clock = TestClock(Fixtures.date2)
    let ids = SequentialIDs(startingAt: 500)
    let repository: InMemoryRepository
    let container: AppContainer

    init(jobs: [Job] = [], referrals: [Referral] = []) {
        let changes = changes
        let clock = clock
        let ids = ids
        repository = InMemoryRepository(jobs: jobs, referrals: referrals, onChange: { changes.send() })
        container = AppContainer(
            jobRepository: repository,
            referralRepository: repository,
            changeObserver: changes,
            now: { clock.now },
            makeID: { ids.make() }
        )
    }
}

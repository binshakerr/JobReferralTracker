import Foundation

/// Composition root: the only place that knows the concrete Data-layer types.
/// Created once by `AppBootstrapper` and passed down as a `ViewModelFactory`.
@MainActor
final class AppContainer {
    private let jobRepository: JobRepository
    private let referralRepository: ReferralRepository
    private let liveQuery: LiveQuery
    private let now: DateProvider
    private let makeID: IDGenerator

    init(
        stack: CoreDataStack,
        now: @escaping DateProvider = { Date() },
        makeID: @escaping IDGenerator = { UUID() }
    ) {
        jobRepository = CoreDataJobRepository(stack: stack)
        referralRepository = CoreDataReferralRepository(stack: stack)
        liveQuery = LiveQuery(changeObserver: CoreDataChangeObserver(stack: stack))
        self.now = now
        self.makeID = makeID
    }

    // MARK: - Use cases (cheap value types, built on demand)

    var observeJobSummaries: ObserveJobSummariesUseCase {
        ObserveJobSummariesUseCase(repository: jobRepository, liveQuery: liveQuery)
    }

    var observeJob: ObserveJobUseCase {
        ObserveJobUseCase(repository: jobRepository, liveQuery: liveQuery)
    }

    var createJob: CreateJobUseCase {
        CreateJobUseCase(repository: jobRepository, validator: JobValidator(), now: now, makeID: makeID)
    }

    var updateJob: UpdateJobUseCase {
        UpdateJobUseCase(repository: jobRepository, validator: JobValidator(), now: now)
    }

    var deleteJob: DeleteJobUseCase {
        DeleteJobUseCase(repository: jobRepository)
    }

    var observeReferrals: ObserveReferralsUseCase {
        ObserveReferralsUseCase(repository: referralRepository, liveQuery: liveQuery)
    }

    var observeReferral: ObserveReferralUseCase {
        ObserveReferralUseCase(repository: referralRepository, liveQuery: liveQuery)
    }

    var addReferral: AddReferralUseCase {
        AddReferralUseCase(repository: referralRepository, validator: ReferralValidator(), now: now, makeID: makeID)
    }

    var updateReferral: UpdateReferralUseCase {
        UpdateReferralUseCase(repository: referralRepository, validator: ReferralValidator(), now: now)
    }

    var updateReferralStatus: UpdateReferralStatusUseCase {
        UpdateReferralStatusUseCase(repository: referralRepository, now: now)
    }

    var deleteReferral: DeleteReferralUseCase {
        DeleteReferralUseCase(repository: referralRepository)
    }

    var observeReferralAnalytics: ObserveReferralAnalyticsUseCase {
        ObserveReferralAnalyticsUseCase(jobRepository: jobRepository, referralRepository: referralRepository,
                                        calculator: ReferralAnalyticsCalculator(), liveQuery: liveQuery)
    }

    var observeAllReferrals: ObserveAllReferralsUseCase {
        ObserveAllReferralsUseCase(repository: referralRepository, liveQuery: liveQuery)
    }
}

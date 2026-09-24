import Foundation

/// Live per-job and overall referral status breakdowns.
struct ObserveReferralAnalyticsUseCase: Sendable {
    let jobRepository: JobRepository
    let referralRepository: ReferralRepository
    let calculator: ReferralAnalyticsCalculator
    let liveQuery: LiveQuery

    func execute() -> AsyncThrowingStream<ReferralAnalytics, Error> {
        liveQuery.stream { [jobRepository, referralRepository, calculator] in
            async let jobs = jobRepository.fetchJobs()
            async let referrals = referralRepository.fetchAllReferrals()
            return try await calculator.makeAnalytics(jobs: jobs, referrals: referrals)
        }
    }
}

import Foundation

struct ReferralAnalyticsCalculator: Sendable {
    /// Builds per-job and overall status breakdowns. Referrals whose job is not in `jobs` are ignored.
    func makeAnalytics(jobs: [Job], referrals: [Referral]) -> ReferralAnalytics {
        let jobIDs = Set(jobs.map(\.id))
        let statusesByJob = Dictionary(grouping: referrals.filter { jobIDs.contains($0.jobID) }, by: \.jobID)
            .mapValues { $0.map(\.status) }

        let perJob = jobs
            .map { JobReferralBreakdown(job: $0, breakdown: StatusBreakdown(statuses: statusesByJob[$0.id] ?? [])) }
            .sorted { lhs, rhs in
                if lhs.breakdown.total != rhs.breakdown.total { return lhs.breakdown.total > rhs.breakdown.total }
                return lhs.job.title.localizedCaseInsensitiveCompare(rhs.job.title) == .orderedAscending
            }

        let overall = StatusBreakdown(statuses: statusesByJob.values.joined())
        return ReferralAnalytics(overall: overall, perJob: perJob)
    }
}
